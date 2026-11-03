package com.financetrack.dto;
import jakarta.validation.constraints.*; import java.math.BigDecimal; import java.time.LocalDate;
public record EntryDto(Long id,String category,String description,BigDecimal amount,LocalDate occurredOn) { public record Request(@NotNull Long categoryId,@NotBlank @Size(max=200)String description,@NotNull @DecimalMin("0.01") @Digits(integer=15,fraction=4)BigDecimal amount,@NotNull LocalDate occurredOn){} }
