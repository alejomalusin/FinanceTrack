package com.financetrack.dto;
import jakarta.validation.constraints.*;
public final class AuthDtos {private AuthDtos(){} public record Register(@NotBlank @Size(max=120)String fullName,@Email @NotBlank String email,@Size(min=10,max=72)String password){} public record Login(@Email @NotBlank String email,@NotBlank String password){} public record AuthResponse(String accessToken,String tokenType,String name,String email){} }
