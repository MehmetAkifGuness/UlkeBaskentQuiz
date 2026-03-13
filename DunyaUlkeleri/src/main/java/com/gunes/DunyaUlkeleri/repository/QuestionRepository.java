package com.gunes.DunyaUlkeleri.repository;

import com.gunes.DunyaUlkeleri.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;

// DÜZELTME: JpaRepository<Question, Long> yapıldı.
@Repository
public interface QuestionRepository extends JpaRepository<Question, Long> {

    @Query(value = "SELECT * FROM question ORDER BY RANDOM() LIMIT 1", nativeQuery = true)
    Optional<Question> findRandomQuestion();

    @Query(value = "SELECT capital_name FROM question WHERE capital_name != :correctAnswer ORDER BY RANDOM() LIMIT 3", nativeQuery = true)
    List<String> findRandomWrongAnswers(@Param("correctAnswer") String correctAnswer);

    // KATEGORİ VE ÖĞRENME MODU İÇİN YENİ METOTLAR
    List<Question> findByContinent(String continent);

    List<Question> findByCountryNameStartingWithOrderByCountryNameAsc(String prefix);
    
    List<Question> findAllByOrderByCountryNameAsc();
    @Query(value = "SELECT * FROM question q WHERE (:category = 'Dünya' OR q.continent = :category) " +
                   "AND q.id NOT IN :askedIds ORDER BY RANDOM() LIMIT 1", nativeQuery = true)
    Optional<Question> findRandomQuestionByCategory(@Param("category")String category , @Param("askedIds")Set<Long> askedIds);
}