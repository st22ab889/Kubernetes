package com.example.polls.controller;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/_status/healthz")
public class StatusController {

    @GetMapping
    public String healthCheck() {
        return "UP";
    }

}
