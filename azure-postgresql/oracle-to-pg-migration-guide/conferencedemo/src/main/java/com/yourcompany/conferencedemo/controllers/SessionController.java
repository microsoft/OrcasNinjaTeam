package com.yourcompany.conferencedemo.controllers;

import com.yourcompany.conferencedemo.models.Session;
import com.yourcompany.conferencedemo.repositories.SessionRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/sessions")
public class SessionController {


    private final SessionRepository sessionRepository;

    public SessionController(SessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }


    @GetMapping
    public List<Session> getSessions() {
        return sessionRepository.findAll();
    }


    @GetMapping("/events/{id}")
    public List<Session> getSessionsByEventId(@PathVariable Long id) {
        return sessionRepository.findByEventId(id);
    }


    @GetMapping("/{id}")
    public Session getSessionsById(@PathVariable Long id) {
        return sessionRepository.findById(id).orElseThrow();
    }

}
