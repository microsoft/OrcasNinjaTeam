package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.Event;
import com.yourcompany.conferencedemo.repositories.EventRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/events")
public class EventController {

    private EventRepository eventRepository;

    public EventController(EventRepository eventRepository) {
        this.eventRepository = eventRepository;
    }

    @GetMapping("/test")
    public String test() {
        return "Congratulations!  Your test passed.";
    }


    @GetMapping
    public List<Event> getEvents() {
        return eventRepository.findAll();
    }
}
