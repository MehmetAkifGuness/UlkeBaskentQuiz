package com.gunes.DunyaUlkeleri.serviceimp;

import com.gunes.DunyaUlkeleri.dto.request.GameAnswerRequest;
import com.gunes.DunyaUlkeleri.dto.response.DictionaryResponse;
import com.gunes.DunyaUlkeleri.dto.response.GameStatusResponse;
import com.gunes.DunyaUlkeleri.entity.GameSession;
import com.gunes.DunyaUlkeleri.entity.Question;
import com.gunes.DunyaUlkeleri.entity.User;
import com.gunes.DunyaUlkeleri.util.exception.AppException;
import com.gunes.DunyaUlkeleri.repository.GameSessionRepository;
import com.gunes.DunyaUlkeleri.repository.QuestionRepository;
import com.gunes.DunyaUlkeleri.repository.UserRepository;
import com.gunes.DunyaUlkeleri.service.DictionaryQueryService;
import com.gunes.DunyaUlkeleri.service.GameService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Transactional
public class GameServiceImpl implements GameService {

    private final QuestionRepository questionRepository;
    private final UserRepository userRepository;
    private final GameSessionRepository gameSessionRepository;
    private final DictionaryQueryService dictionaryQueryService;
    private final DailyChallengeService dailyChallengeService;
    private final GameSessionCleanupService sessionCleanupService;
    private final GameQuestionService gameQuestionService;
    private final GameAnswerService gameAnswerService;

    @Override
    public GameStatusResponse startGame(String username, String category, String mode) { 
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı: " + username));

        // ==============================================================================
        // 🚨 UX VE MANTIK YAMASI: ZOMBİ OYUNLARI ENGELLEME 
        // Kullanıcı "Kaldığın Yerden Devam Et" yerine YENİ bir oyuna giriyorsa, 
        // eski yarım kalmış tüm oyunları "Terk Edildi (Finished = true)" olarak işaretle.
        // ==============================================================================
        sessionCleanupService.abandonUnfinishedSessions(user);

        // 🚨 GÜNÜN GÖREVİ KONTROLÜ VE HİLE KORUMASI
        if (dailyChallengeService.isDailyCategory(category)) {
            dailyChallengeService.validateAndConsumeDailyAttempt(user);
            userRepository.save(user);
        }

        GameSession session = new GameSession();
        session.setUser(user);
        session.setCategory(category); 
        session.setGameMode(mode); 
        
        if (dailyChallengeService.isDailyCategory(category) || "ENDLESS".equals(mode)) {
            session.setRemainingLives(1); 
        } else {
            session.setRemainingLives(3);
        }

        session = gameSessionRepository.save(session); 

        return gameQuestionService.generateNextQuestion(session);
    }

    // 🚨 YARIM KALAN OYUNU CANLANDIRMA METODU (RESUME GAME)
    @Override
    public GameStatusResponse resumeGame(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> AppException.notFound("USER_NOT_FOUND", "Kullanıcı bulunamadı."));

        // Kullanıcının bitmemiş (yarım kalmış) oyununu bul
        Optional<GameSession> activeSessionOpt = gameSessionRepository.findFirstByUserAndIsFinishedFalseOrderByUpdateAtDesc(user);
        
        if (activeSessionOpt.isEmpty()) {
            return null; // Yarım kalan oyun yok
        }
        
        GameSession session = activeSessionOpt.get();
        
        // 🚨 BUG ÇÖZÜMÜ: Eski günden kalan "Günün Görevi"ne ertesi gün devam edilemez!
        if ("DailyChallenge".equals(session.getCategory())) {
            if (!session.getCreatedAt().toLocalDate().equals(LocalDate.now())) {
                session.setFinished(true); 
                gameSessionRepository.save(session);
                return null; 
            }
        }
        
        Question question = questionRepository.findById(session.getCurrentQuestionId()).orElse(null);
        
        if (question == null) {
            session.setFinished(true);
            gameSessionRepository.save(session);
            return null;
        }

        return gameQuestionService.buildResumeResponse(session, question);
    }

    @Override
    public GameStatusResponse submitAnswer(GameAnswerRequest request, String username) {
        return gameAnswerService.submitAnswer(request, username);
    }

    // =================================================================
    // 🚨 İŞTE EFSANE SÖZLÜK METODU BURADA, SAPASAĞLAM DURUYOR! 🚨
    // =================================================================
    @Override
    public List<DictionaryResponse> getDictionary() {
        return dictionaryQueryService.getDictionary();
    }
}
