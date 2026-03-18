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
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
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
    public GameStatusResponse startGame(String username, String category) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + username));

        // 🚨 GÜNÜN GÖREVİ KONTROLÜ: Kullanıcı bugün zaten oynamış mı?
        if ("DailyChallenge".equals(category)) {
            if (user.getLastDailyDate() != null && user.getLastDailyDate().equals(LocalDate.now())) {
                throw new RuntimeException("Bugün zaten Günün Görevi'ni tamamladın! Yarın tekrar gel.");
            }
        }

        GameSession session = new GameSession();
        session.setUser(user);
        session.setCategory(category); // Seçilen kategoriyi oturuma kaydediyoruz
        
        // Günün görevinde can sınırı yok, sadece 10 soru sınırı var. O yüzden canı sembolik olarak yüksek tutabiliriz.
        if ("DailyChallenge".equals(category)) {
            session.setRemainingLives(1); 
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

        String previousCorrectAnswer = session.getCurrentCorrectAnswer();
        Long previousQuestionId = session.getCurrentQuestionId(); // Cevapladığımız sorunun ID'si
        
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
            // YANLIŞ BİLDİYSE
            User user = session.getUser();
            Question currentQuestion = questionRepository.findById(session.getCurrentQuestionId()).orElse(null);
            
            if (currentQuestion != null) {
                user.getFailedQuestions().add(currentQuestion);
                userRepository.save(user); // Soruyu kullanıcının hata listesine ekle
            }
            if (isDaily) {
                // 🚨 GÜNÜN GÖREVİ MODU: Yanlış yapsa da can düşmez, soru pas geçilir.
                if (previousQuestionId != null) {
                    session.getAskedQuestionIds().add(previousQuestionId);
                }
            } else {
                // NORMAL MOD: Can Düşür
                session.setRemainingLives(session.getRemainingLives() - 1);
            }
        }

        // --- OYUN BİTME KONTROLÜ ---
        boolean gameFinished = false;
        User user = session.getUser();

        if (isDaily) {
            // 🚨 GÜNÜN GÖREVİ BİTİŞ KONTROLÜ: 10 Soru cevaplandı mı?
            if (session.getAskedQuestionIds().size() >= 10) {
                gameFinished = true;
                user.setLastDailyDate(LocalDate.now()); // BUGÜN OYNADI OLARAK İŞARETLE!
            }
        } else {
            // NORMAL MOD BİTİŞ KONTROLÜ: Can 0 oldu mu?
            if (session.getRemainingLives() <= 0) {
                gameFinished = true;
            }
        }

        if (gameFinished) {
            session.setFinished(true);
            
            String currentCategory = session.getCategory() == null ? "Dünya" : session.getCategory();
            int currentScore = session.getCurrentScore();
            int bestScore = user.getCategoryBestScores().getOrDefault(currentCategory, 0);
            
            if (currentScore > bestScore) {
                user.getCategoryBestScores().put(currentCategory, currentScore);
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
        
        // Yeni soruyu üret
        GameStatusResponse response = generateNextQuestion(session);
        response.setLastCorrectAnswer(previousCorrectAnswer);
        response.setLastAnswerCorrect(isCorrect);
        return response;
    }

    private GameStatusResponse generateNextQuestion(GameSession session) {
        boolean isDaily = "DailyChallenge".equals(session.getCategory());
        Question question = null;

        if (isDaily) {
            // 🚨 GÜNÜN GÖREVİ: O günkü sabit 10 soruyu al ve sıradakini bul
            List<Question> dailyQuestions = getDailyQuestions();
            for (Question q : dailyQuestions) {
                if (!session.getAskedQuestionIds().contains(q.getId())) {
                    question = q;
                    break;
                }
            }
        } else {
            // NORMAL MOD: Rastgele soru getir
            Set<Long> askedIds = session.getAskedQuestionIds().isEmpty() ? Set.of(-1L) : session.getAskedQuestionIds();
            String category = (session.getCategory() == null || session.getCategory().isEmpty()) ? "Dünya" : session.getCategory();
            question = questionRepository.findRandomQuestionByCategory(category, askedIds).orElse(null);
        }

        // KATEGORİYİ BİTİRME (KAZANMA) DURUMU
        if (question == null) {
            session.setFinished(true); 
            User user = session.getUser();
            
            // Eğer normal modsa ve tüm sorular bittiyse bonus ekle
            if (!isDaily) {
                session.setCurrentScore(session.getCurrentScore() + 5000);
            }

            String currentCategory = session.getCategory() == null ? "Dünya" : session.getCategory();
            int currentScore = session.getCurrentScore();
            int bestScore = user.getCategoryBestScores().getOrDefault(currentCategory, 0);
            
            if (currentScore > bestScore) {
                user.getCategoryBestScores().put(currentCategory, currentScore);
            }

            if (currentScore > user.getMaxWinStreak()) {
                user.setMaxWinStreak(currentScore);
            }
            user.setTotalGamesPlayed(user.getTotalGamesPlayed() + 1);
            
            if (isDaily) {
                user.setLastDailyDate(LocalDate.now()); // Günlük görev başarıyla bitti
            }
            
            userRepository.save(user);
            gameSessionRepository.save(session);

            String msg = isDaily ? "Günün Görevi Tamamlandı! Harika iş çıkardın." : "TEBRİKLER! Bu kategorideki tüm ülkeleri bildiniz! (+5000 Bonus)";
            return buildResponse(session, msg, true);
        }

        // Soru varsa normal şekilde devam et
        List<String> options = new ArrayList<>();
        options.add(question.getCapitalName()); 
        options.addAll(questionRepository.findRandomWrongAnswers(question.getCapitalName())); 
        Collections.shuffle(options);

        session.setCurrentCorrectAnswer(question.getCapitalName());
        session.setCurrentQuestionId(question.getId());
        gameSessionRepository.save(session);

        GameStatusResponse response = buildResponse(session, "Yeni Soru!", false);
        response.setCountryName(question.getCountryName());
        response.setOptions(options);
        
        // 🚨 Sadece Günlük Görevde kaçıncı soruda olduğunu göstermek için ufak bir hile:
        if (isDaily) {
            response.setMessage("Günün Görevi: Soru " + (session.getAskedQuestionIds().size() + 1) + "/10");
        }
        
        return response;
    }

    // 🚨 YENİ EKLENDİ: O güne özel HERKES İÇİN AYNI olan 10 soruyu belirler
    private List<Question> getDailyQuestions() {
        List<Question> allQuestions = questionRepository.findAllByOrderByCountryNameAsc(); // Tüm soruları sabit sırada al
        long seed = LocalDate.now().toEpochDay(); // Bugünün tarihini şifre (seed) yap
        Collections.shuffle(allQuestions, new Random(seed)); // Rastgele ama herkes için aynı dizilim
        return allQuestions.stream().limit(10).collect(Collectors.toList()); // Sadece ilk 10'unu al
    }

    private GameStatusResponse buildResponse(GameSession session, String message, boolean isFinished) {
        GameStatusResponse response = new GameStatusResponse();
        response.setSessionId(session.getId());
        response.setCurrentScore(session.getCurrentScore());
        response.setRemainingLives(session.getRemainingLives());
        response.setMessage(message);
        response.setFinished(isFinished);
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