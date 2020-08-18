package com.yourcompany.conferencedemo.repositories;

import com.yourcompany.conferencedemo.models.Session;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SessionRepository extends JpaRepository<Session, Long> {
    List<Session> findByEventId(Long eventId);
}
