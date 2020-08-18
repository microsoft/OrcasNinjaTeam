package com.yourcompany.conferencedemo.controllers;


import com.yourcompany.conferencedemo.models.Registration;
import com.yourcompany.conferencedemo.repositories.RegistrationRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/registrations")
public class RegistrationController {

    private final RegistrationRepository registrationRepository;

    public RegistrationController(RegistrationRepository registrationRepository) {
        this.registrationRepository = registrationRepository;
    }


    @GetMapping
    public List<Registration> getRegistrations() {
        return registrationRepository.findAll();
    }


    @PostMapping
    public Registration addRegistration(@RequestBody Registration registration) {
        registrationRepository.registerAttendee(registration.getSessionId(), registration.getAttendeeId());
        return registration;
    }
}
