package com.financetrack.controller;
import com.financetrack.entity.User;import com.financetrack.repository.UserRepository;import jakarta.validation.Valid;import jakarta.validation.constraints.*;import org.springframework.security.core.Authentication;import org.springframework.security.crypto.password.PasswordEncoder;import org.springframework.web.bind.annotation.*;import java.util.*;
@RestController @RequestMapping("/api/profile")public class ProfileController{
 public record ProfileUpdate(@NotBlank @Size(max=120)String fullName,@Email @NotBlank String email,@Size(min=10,max=72)String newPassword){}
 private final UserRepository users;private final PasswordEncoder encoder;public ProfileController(UserRepository u,PasswordEncoder e){users=u;encoder=e;}private User current(Authentication a){return users.findByEmailIgnoreCase(a.getName()).orElseThrow();}
 @GetMapping public Map<String,Object> get(Authentication a){User u=current(a);return Map.of("id",u.getId(),"fullName",u.getFullName(),"email",u.getEmail());}
 @PutMapping public Map<String,Object> update(@Valid @RequestBody ProfileUpdate p,Authentication a){User u=current(a);String email=p.email().trim().toLowerCase();users.findByEmailIgnoreCase(email).filter(existing->!existing.getId().equals(u.getId())).ifPresent(x->{throw new IllegalArgumentException("El correo ya está registrado");});u.setFullName(p.fullName().trim());u.setEmail(email);if(p.newPassword()!=null&&!p.newPassword().isBlank())u.setPasswordHash(encoder.encode(p.newPassword()));users.save(u);return Map.of("fullName",u.getFullName(),"email",u.getEmail());}
}
