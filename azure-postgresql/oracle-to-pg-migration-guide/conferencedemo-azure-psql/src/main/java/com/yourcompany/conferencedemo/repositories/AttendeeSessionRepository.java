package com.yourcompany.conferencedemo.repositories;

import com.yourcompany.conferencedemo.models.AttendeeSession;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AttendeeSessionRepository extends JpaRepository<AttendeeSession, Long> {
}
