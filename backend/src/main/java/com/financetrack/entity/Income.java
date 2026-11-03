package com.financetrack.entity;
import jakarta.persistence.*;
@Entity @Table(name="income") public class Income extends FinancialEntry { protected Income(){} public Income(User u,Category c,String d,java.math.BigDecimal a,java.time.LocalDate date){user=u;category=c;description=d;amount=a;occurredOn=date;} }
