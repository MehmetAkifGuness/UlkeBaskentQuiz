package com.gunes.DunyaUlkeleri.service.impl;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.GameService;
import org.springframework.data.domain.PageRequest; 
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration; // 🚨 YENİ EKLENDİ
import java.time.LocalDate;
import java.time.LocalDateTime; // 🚨 YENİ EKLENDİ
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class GameServiceImpl implements GameService {

    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;

    @Override
    public GameStatusResponse startGame(String username, String category, String mode) { 
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + username));

        // 🚨 GÜNÜN GÖREVİ KONTROLÜ
        if ("DailyChallenge".equals(category)) {
            if (user.getLastDailyDate() != null && user.getLastDailyDate().equals(LocalDate.now())) {
                throw new RuntimeException("Bugün zaten Günün Görevi'ni tamamladın! Yarın tekrar gel.");
            }
        }

        GameSession session = new GameSession();
        session.setUser(user);
        session.setCategory(category); 
        session.setGameMode(mode); 
        
        // 🚨 YENİ EKLENDİ: Başlangıçta canları kesin olarak atıyoruz
        if ("DailyChallenge".equals(category) || "ENDLESS".equals(mode)) {
            session.setRemainingLives(1); 
        } else {
            session.setRemainingLives(3);
        }

        session = gameSessionRepository.save(session); 

        return generateNextQuestion(session);
    }

    @Override
    public GameStatusResponse submitAnswer(GameAnswerRequest request, String username) {
        GameSession session = gameSessionRepository.findById(request.getSessionId())
                .orElseThrow(() -> new RuntimeException("Oyun oturumu bulunamadı!"));

        if (!session.getUser().getUsername().equals(username)) {
            throw new RuntimeException("Güvenlik İhlali: Bu oyun oturumu size ait değil!");
        }

        if (session.isFinished()) {
            return buildResponse(session, "Bu oyun zaten bitmiş!", true);
        }

        // 🚨 GÜVENLİK YAMASI: Anti-Spam / Anti-Bot Kontrolü (0.1 Saniye Sınırı)
        if (session.getLastQuestionTime() != null) {
            long timeElapsedMillis = Duration.between(session.getLastQuestionTime(), LocalDateTime.now()).toMillis();
            if (timeElapsedMillis < 100) { // 🚨 100 milisaniye (0.1 saniye)
                throw new RuntimeException("Güvenlik İhlali: Çok hızlı cevap gönderildi (Hile şüphesi)!");
            }
        }

        String previousCorrectAnswer = session.getCurrentCorrectAnswer();
        Long previousQuestionId = session.getCurrentQuestionId(); 
        
        boolean isCorrect = request.getCapitalGuess().trim().equalsIgnoreCase(previousCorrectAnswer);
        boolean isDaily = "DailyChallenge".equals(session.getCategory());

        if (isCorrect) {
            double timeInSeconds = request.getTimeTaken();
            int earnedScore;
            
            if (timeInSeconds > 10.0) {
                earnedScore = 100;
            } else {
                if (timeInSeconds < 0.1) timeInSeconds = 0.1;
                earnedScore = (int) Math.round((10.0 / timeInSeconds) * 200.0);
                if (earnedScore > 2000) {
                    earnedScore = 2000; 
                }
            }
            
            System.out.println("Süre: " + timeInSeconds + " sn | Kazanılan Puan: " + earnedScore);
            session.setCurrentScore(session.getCurrentScore() + earnedScore);
            
            if (previousQuestionId != null) {
                session.getAskedQuestionIds().add(previousQuestionId);
            }
        }
        else {
            User user = session.getUser();
            Question currentQuestion = questionRepository.findById(session.getCurrentQuestionId()).orElse(null);
            
            if (currentQuestion != null) {
                user.getFailedQuestions().add(currentQuestion);
                userRepository.save(user); 
            }
            if (isDaily) {
                if (previousQuestionId != null) {
                    session.getAskedQuestionIds().add(previousQuestionId);
                }
            } else if ("ENDLESS".equals(session.getGameMode())) {
                // 🚨 YENİ EKLENDİ: Sonsuz modda 1 yanlış yapıldığı an can direkt 0 yapılır (Kesin elenme garantisi)
                session.setRemainingLives(0);
            } else {
                session.setRemainingLives(session.getRemainingLives() - 1);
            }
        }

        // --- OYUN BİTME KONTROLÜ ---
        boolean gameFinished = false;
        User user = session.getUser();

        if (isDaily) {
            if (session.getAskedQuestionIds().size() >= 10) {
                gameFinished = true;
                user.setLastDailyDate(LocalDate.now()); 
            }
        } else {
            if (session.getRemainingLives() <= 0) {
                gameFinished = true;
            }
        }

        if (gameFinished) {
            session.setFinished(true);
            
            // 🚨 YENİ VE AKILLI USTALIK PUANI KAYDEDİCİ (MODA GÖRE AYIRIR)
            String currentCategory = session.getCategory() == null ? "Dünya" : session.getCategory();
            String currentMode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            String mapKey = currentCategory + "_" + currentMode; // Örn: "Avrupa_COUNTRY_TO_CAPITAL"

            int currentScore = session.getCurrentScore();
            int bestScore = user.getCategoryBestScores().getOrDefault(mapKey, 0);
            
            if (currentScore > bestScore) {
                user.getCategoryBestScores().put(mapKey, currentScore); // Artık puanlar ezilmeyecek!
            }

            if (session.getCurrentScore() > user.getMaxWinStreak()) {
                user.setMaxWinStreak(session.getCurrentScore());
            }
            user.setTotalGamesPlayed(user.getTotalGamesPlayed() + 1);
            
            userRepository.save(user);
            gameSessionRepository.save(session);
            
            GameStatusResponse response = buildResponse(session, "Oyun Bitti! Toplam Skor: " + session.getCurrentScore(), true);
            response.setLastCorrectAnswer(previousCorrectAnswer);
            response.setLastAnswerCorrect(isCorrect);
            return response;
        }

        gameSessionRepository.save(session);
        
        GameStatusResponse response = generateNextQuestion(session);
        response.setLastCorrectAnswer(previousCorrectAnswer);
        response.setLastAnswerCorrect(isCorrect);
        return response;
    }

    private GameStatusResponse generateNextQuestion(GameSession session) {
        boolean isDaily = "DailyChallenge".equals(session.getCategory());
        Question question = null;

        if (isDaily) {
            List<Question> dailyQuestions = getDailyQuestions();
            for (Question q : dailyQuestions) {
                if (!session.getAskedQuestionIds().contains(q.getId())) {
                    question = q;
                    break;
                }
            }
        } else {
            Set<Long> askedIds = session.getAskedQuestionIds().isEmpty() ? Set.of(-1L) : session.getAskedQuestionIds();
            String category = (session.getCategory() == null || session.getCategory().isEmpty()) ? "Dünya" : session.getCategory();
            question = questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);

            // 🚨 YENİ EKLENDİ: Gerçek Sonsuzluk (Eğer sorular tükenirse listeyi sıfırla ve yeniden soru seç)
            if (question == null && "ENDLESS".equals(session.getGameMode())) {
                session.getAskedQuestionIds().clear();
                askedIds = Set.of(-1L);
                question = questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);
            }
        }

        if (question == null) {
            session.setFinished(true); 
            User user = session.getUser();
            
            if (!isDaily) {
                session.setCurrentScore(session.getCurrentScore() + 5000);
            }

            // 🚨 KATEGORİ BİTİRİLDİĞİNDE DE MODA GÖRE KAYDEDİYORUZ
            String currentCategory = session.getCategory() == null ? "Dünya" : session.getCategory();
            String currentMode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            String mapKey = currentCategory + "_" + currentMode;

            int currentScore = session.getCurrentScore();
            int bestScore = user.getCategoryBestScores().getOrDefault(mapKey, 0);
            
            if (currentScore > bestScore) {
                user.getCategoryBestScores().put(mapKey, currentScore);
            }

            if (currentScore > user.getMaxWinStreak()) {
                user.setMaxWinStreak(currentScore);
            }
            user.setTotalGamesPlayed(user.getTotalGamesPlayed() + 1);
            
            if (isDaily) {
                user.setLastDailyDate(LocalDate.now()); 
            }
            
            userRepository.save(user);
            gameSessionRepository.save(session);

            String msg = isDaily ? "Günün Görevi Tamamlandı! Harika iş çıkardın." : "TEBRİKLER! Bu kategorideki tüm ülkeleri bildiniz! (+5000 Bonus)";
            return buildResponse(session, msg, true);
        }

        boolean askForCapital = true;
        if (isDaily) {
            long seed = LocalDate.now().toEpochDay() + question.getId();
            askForCapital = new Random(seed).nextBoolean();
        } else {
            String mode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            if ("COUNTRY_TO_CAPITAL".equals(mode)) {
                askForCapital = true;
            } else if ("CAPITAL_TO_COUNTRY".equals(mode)) {
                askForCapital = false;
            } else {
                askForCapital = Math.random() < 0.5; 
            }
        }

        List<String> options = new ArrayList<>();
        String correctAnswer;
        String questionText;

        if (askForCapital) {
            correctAnswer = question.getCapitalName();
            options.add(correctAnswer);
            options.addAll(questionRepository.findRandomWrongAnswers(correctAnswer)); 
            questionText = question.getCountryName() + " ülkesinin başkenti neresidir?";
        } else {
            correctAnswer = question.getCountryName();
            options.add(correctAnswer);
            options.addAll(questionRepository.findRandomWrongCountries(correctAnswer)); 
            questionText = question.getCapitalName() + " şehri hangi ülkenin başkentidir?";
        }
        Collections.shuffle(options);

        session.setCurrentCorrectAnswer(correctAnswer);
        session.setCurrentQuestionId(question.getId());

        // 🚨 GÜVENLİK YAMASI: Yeni sorunun sorulma zamanını kaydediyoruz
        session.setLastQuestionTime(LocalDateTime.now());

        gameSessionRepository.save(session);

        GameStatusResponse response = buildResponse(session, "Yeni Soru!", false);
        response.setCountryName(question.getCountryName());
        response.setQuestionText(questionText); 
        response.setOptions(options);
        
        if (isDaily) {
            response.setMessage("Günün Görevi: Soru " + (session.getAskedQuestionIds().size() + 1) + "/10");
        }
        
        return response;
    }

    private List<Question> getDailyQuestions() {
        List<Question> allQuestions = questionRepository.findAllByOrderByCountryNameAsc(); 
        long seed = LocalDate.now().toEpochDay(); 
        Collections.shuffle(allQuestions, new Random(seed)); 
        return allQuestions.stream().limit(10).collect(Collectors.toList()); 
    }

    private void calculateGhostAndQuestions(GameSession session, GameStatusResponse response) {
        String category = session.getCategory() == null ? "Dünya" : session.getCategory();
        boolean isDaily = "DailyChallenge".equals(category);
        
        int totalQ;
        if (isDaily) {
            totalQ = 10;
        } else {
            if ("Dünya".equals(category)) {
                totalQ = (int) questionRepository.count();
            } else {
                totalQ = questionRepository.findByContinent(category).size();
            }
        }
        
        int remainingQ = totalQ - session.getAskedQuestionIds().size();
        
        response.setTotalQuestions(totalQ);
        response.setRemainingQuestions(remainingQ);

        List<Object[]> topUsers;
        if (isDaily) {
            topUsers = gameSessionRepository.findTop10DailyScores(category, LocalDate.now().atStartOfDay(), PageRequest.of(0, 1));
        } else {
            String mode = session.getGameMode() == null ? "MIXED" : session.getGameMode();
            topUsers = gameSessionRepository.findTop10ByCategoryAndMode(category, mode, PageRequest.of(0, 1));
        }

        if (topUsers != null && !topUsers.isEmpty() && topUsers.get(0)[1] != null && ((Integer)topUsers.get(0)[1]) > 0) {
            Object[] topPlayer = topUsers.get(0);
            response.setGhostName((String) topPlayer[0]);
            response.setGhostScore((Integer) topPlayer[1]);
        } else {
            response.setGhostName("Rekor Yok");
            response.setGhostScore(0);
        }
    }

    private GameStatusResponse buildResponse(GameSession session, String message, boolean isFinished) {
        GameStatusResponse response = new GameStatusResponse();
        response.setSessionId(session.getId());
        response.setCurrentScore(session.getCurrentScore());
        response.setRemainingLives(session.getRemainingLives());
        response.setMessage(message);
        response.setFinished(isFinished);
        
        calculateGhostAndQuestions(session, response);
        
        return response;
    }

    @Override
    public List<DictionaryResponse> getDictionary() {
        List<Question> allQuestions = questionRepository.findAllByOrderByCountryNameAsc();
        return allQuestions.stream().map(q -> new DictionaryResponse(
                q.getCountryName(),
                q.getCapitalName(),
                q.getContinent()
        )).collect(Collectors.toList());
    }
}