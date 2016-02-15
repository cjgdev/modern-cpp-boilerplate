#ifndef TEST_COMMON_HPP
#define TEST_COMMON_HPP

#include <log4cxx/logger.h>
#include <log4cxx/xml/domconfigurator.h>

#include <gmock/gmock.h>
#include <gtest/gtest.h>

// -----------------------------------------------------------------------------
// CONSTANTS

static const std::string kTestResourceDir = "resources/";

// -----------------------------------------------------------------------------
// TEST ENVIRONMENT

class TestEnvironment : public ::testing::Environment {
public:
    virtual void SetUp() override {
        xml::DOMConfigurator::configure(kTestResourceDir + "log4cxx.xml");
    }
    virtual void TearDown() override {
        //
    }
};

#endif // TEST_COMMON_HPP