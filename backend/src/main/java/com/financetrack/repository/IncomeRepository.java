package com.financetrack.repository;
import com.financetrack.entity.Income; import org.springframework.data.jpa.repository.JpaRepository; import java.time.LocalDate; import java.util.*;
public interface IncomeRepository extends JpaRepository<Income,Long>{List<Income> findByUserIdAndOccurredOnBetweenOrderByOccurredOnDesc(Long userId,LocalDate from,LocalDate to); Optional<Income> findByIdAndUserId(Long id,Long userId);}
