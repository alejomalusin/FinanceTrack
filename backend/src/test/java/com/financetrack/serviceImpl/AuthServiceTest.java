package com.financetrack.serviceImpl;

import com.financetrack.dto.AuthDtos.Register;
import com.financetrack.entity.User;
import com.financetrack.repository.UserRepository;
import com.financetrack.security.JwtService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    @Mock UserRepository users;
    @Mock PasswordEncoder passwords;
    @Mock JwtService jwt;
    @InjectMocks AuthService service;

    @Test void registrationNormalizesEmailAndHashesPassword() {
        when(users.findByEmailIgnoreCase("ana@example.com")).thenReturn(Optional.empty());
        when(passwords.encode("a-secure-password")).thenReturn("bcrypt-hash");
        when(users.save(any(User.class))).thenAnswer(call -> call.getArgument(0));
        when(jwt.issue("ana@example.com")).thenReturn("signed-token");

        var result = service.register(new Register("Ana Pérez", " Ana@Example.com ", "a-secure-password"));

        assertEquals("signed-token", result.accessToken());
        assertEquals("ana@example.com", result.email());
        verify(passwords).encode("a-secure-password");
        verify(users).save(argThat(user -> user.getPasswordHash().equals("bcrypt-hash")));
    }

    @Test void duplicateEmailIsRejected() {
        when(users.findByEmailIgnoreCase("ana@example.com")).thenReturn(Optional.of(new User("Ana", "ana@example.com", "hash")));
        assertThrows(IllegalArgumentException.class, () -> service.register(new Register("Ana", "ana@example.com", "a-secure-password")));
        verify(users, never()).save(any());
    }
}
