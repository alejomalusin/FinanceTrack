package com.financetrack.entity;
import jakarta.persistence.*;
@Entity @Table(name="expenses") public class Expense extends FinancialEntry { protected Expense(){} public Expense(User u,Category c,String d,java.math.BigDecimal a,java.time.LocalDate date){user=u;category=c;description=d;amount=a;occurredOn=date;} }
