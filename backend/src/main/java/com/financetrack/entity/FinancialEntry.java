package com.financetrack.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@MappedSuperclass
public abstract class FinancialEntry {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) protected Long id;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="user_id",nullable=false) protected User user;
    @ManyToOne(fetch=FetchType.LAZY,optional=false) @JoinColumn(name="category_id",nullable=false) protected Category category;
    @Column(nullable=false,length=200) protected String description;
    @Column(nullable=false,precision=19,scale=4) protected BigDecimal amount;
    @Column(name="occurred_on",nullable=false) protected LocalDate occurredOn;
    protected FinancialEntry() {}
    public Long getId(){return id;} public Category getCategory(){return category;} public String getDescription(){return description;} public BigDecimal getAmount(){return amount;} public LocalDate getOccurredOn(){return occurredOn;}
    public void update(Category category,String description,BigDecimal amount,LocalDate date){this.category=category;this.description=description;this.amount=amount;this.occurredOn=date;}
}
