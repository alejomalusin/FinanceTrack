package com.financetrack.serviceImpl;
import com.financetrack.dto.AuthDtos.*; import com.financetrack.entity.User; import com.financetrack.repository.UserRepository; import com.financetrack.security.JwtService; import org.springframework.security.crypto.password.PasswordEncoder; import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional;
@Service @Transactional public class AuthService {
 private final UserRepository users; private final PasswordEncoder passwords; private final JwtService jwt;
 public AuthService(UserRepository users,PasswordEncoder passwords,JwtService jwt){this.users=users;this.passwords=passwords;this.jwt=jwt;}
 public AuthResponse register(Register r){String email=r.email().trim().toLowerCase();if(users.findByEmailIgnoreCase(email).isPresent())throw new IllegalArgumentException("El correo ya está registrado");User u=users.save(new User(r.fullName().trim(),email,passwords.encode(r.password())));return new AuthResponse(jwt.issue(email),"Bearer",u.getFullName(),email);}
 public AuthResponse login(Login r){User u=users.findByEmailIgnoreCase(r.email()).orElseThrow(()->new IllegalArgumentException("Credenciales incorrectas"));if(!passwords.matches(r.password(),u.getPasswordHash()))throw new IllegalArgumentException("Credenciales incorrectas");return new AuthResponse(jwt.issue(u.getEmail()),"Bearer",u.getFullName(),u.getEmail());}
}
