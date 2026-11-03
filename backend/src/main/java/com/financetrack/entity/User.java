package com.financetrack.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity @Table(name="users")
public class User {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(name="full_name", nullable=false, length=120) private String fullName;
    @Column(nullable=false, unique=true, length=254) private String email;
    @Column(name="password_hash", nullable=false, length=100) private String passwordHash;
    @Column(nullable=false) private boolean enabled=true;
    @Column(name="created_at", nullable=false, updatable=false) private Instant createdAt=Instant.now();
    protected User() {}
    public User(String fullName,String email,String passwordHash){this.fullName=fullName;this.email=email;this.passwordHash=passwordHash;}
    public Long getId(){return id;} public String getFullName(){return fullName;} public void setFullName(String s){fullName=s;}
    public String getEmail(){return email;} public void setEmail(String s){email=s;} public String getPasswordHash(){return passwordHash;} public void setPasswordHash(String s){passwordHash=s;} public boolean isEnabled(){return enabled;}
}
