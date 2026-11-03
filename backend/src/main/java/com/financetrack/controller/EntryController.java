package com.financetrack.controller;
import com.financetrack.dto.EntryDto;import com.financetrack.dto.EntryDto.Request;import com.financetrack.serviceImpl.EntryService;import com.financetrack.repository.UserRepository;import jakarta.validation.Valid;import jakarta.servlet.http.HttpServletRequest;import org.springframework.format.annotation.DateTimeFormat;import org.springframework.security.core.Authentication;import org.springframework.web.bind.annotation.*;import java.time.*;import java.util.*;
@RestController @RequestMapping("/api") public class EntryController {
 private final EntryService service;private final UserRepository users;public EntryController(EntryService s,UserRepository u){service=s;users=u;}
 private Long uid(Authentication a){return users.findByEmailIgnoreCase(a.getName()).orElseThrow().getId();}private String type(HttpServletRequest r){return r.getRequestURI().contains("income")?"income":"expense";}
 @GetMapping({"/income","/expenses"}) public List<EntryDto> list(@RequestParam(required=false)@DateTimeFormat(iso=DateTimeFormat.ISO.DATE)LocalDate from,@RequestParam(required=false)@DateTimeFormat(iso=DateTimeFormat.ISO.DATE)LocalDate to,Authentication auth,HttpServletRequest req){LocalDate today=LocalDate.now();return service.list(type(req),uid(auth),from==null?today.withDayOfMonth(1):from,to==null?today:to);}
 @PostMapping({"/income","/expenses"}) public EntryDto create(@Valid @RequestBody Request body,Authentication auth,HttpServletRequest req){return service.create(type(req),uid(auth),body);}
 @PutMapping({"/income/{id}","/expenses/{id}"}) public EntryDto update(@PathVariable Long id,@Valid @RequestBody Request body,Authentication auth,HttpServletRequest req){return service.update(type(req),uid(auth),id,body);}
 @DeleteMapping({"/income/{id}","/expenses/{id}"}) public void delete(@PathVariable Long id,Authentication auth,HttpServletRequest req){service.delete(type(req),uid(auth),id);}
}
