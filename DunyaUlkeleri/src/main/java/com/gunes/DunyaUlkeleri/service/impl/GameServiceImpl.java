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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
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

        GameSession session = new GameSession();
        session.setUser(user);
        session.setCategory(category); // Seçilen kategoriyi oturuma kaydediyoruz
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

        if (isCorrect) {
            session.setCurrentScore(session.getCurrentScore() + 10);
            
            // EĞER DOĞRU BİLDİYSE: Bu sorunun ID'sini "soruldu" listesine ekle ki bir daha çıkmasın.
            if (previousQuestionId != null) {
                session.getAskedQuestionIds().add(previousQuestionId);
            }
        } else {
            session.setRemainingLives(session.getRemainingLives() - 1);
            // YANLIŞ BİLDİYSE: Listeye EKLEMİYORUZ. Böylece soru havuzda kalmaya devam ediyor.
        }

        // Oyun bittiyse (Can 0 olduysa)
        if (session.getRemainingLives() <= 0) {
            session.setFinished(true);
            User user = session.getUser();
            if (session.getCurrentScore() > user.getMaxWinStreak()) {
                user.setMaxWinStreak(session.getCurrentScore());
                userRepository.save(user);
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
        // Eğer daha önce hiç soru sorulmadıysa Set boş olur. Boş Set SQL'de hata verir. 
        // Bu yüzden varsayılan olarak var olmayan bir ID (-1) ekliyoruz.
        Set<Long> askedIds = session.getAskedQuestionIds().isEmpty() ? Set.of(-1L) : session.getAskedQuestionIds();
        
        // Kategori boş gelmişse varsayılan olarak "Dünya" yapalım
        String category = (session.getCategory() == null || session.getCategory().isEmpty()) ? "Dünya" : session.getCategory();

        // Daha önce sorulmamış ve seçilen kategoriye ait yeni bir soru getir!
        Question question = questionRepository.findRandomQuestionByCategory(category, askedIds)
                .orElseThrow(() -> new RuntimeException("Tebrikler! Bu kategorideki tüm ülkeleri doğru bildiniz!"));

        List<String> options = new ArrayList<>();
        options.add(question.getCapitalName()); 
        options.addAll(questionRepository.findRandomWrongAnswers(question.getCapitalName())); 
        Collections.shuffle(options);

        // Doğru cevabı VE o anki sorunun ID'sini oturuma kaydet ki sonra kontrol edebilelim
        session.setCurrentCorrectAnswer(question.getCapitalName());
        session.setCurrentQuestionId(question.getId());
        gameSessionRepository.save(session);

        GameStatusResponse response = buildResponse(session, "Yeni Soru!", false);
        response.setCountryName(question.getCountryName());
        response.setOptions(options);
        return response;
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