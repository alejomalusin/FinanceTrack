package com.financetrack.entity;

import jakarta.persistence.*;

@Entity @Table(name="categories")
public class Category {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(nullable=false,length=60) private String name;
    @Column(nullable=false,length=12) private String kind;
    protected Category() {}
    public Long getId(){return id;} public String getName(){return name;} public String getKind(){return kind;}
}
