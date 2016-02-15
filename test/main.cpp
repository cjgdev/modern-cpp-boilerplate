#include "test_common.hpp"

#include <iostream>
#include <gmock/gmock.h>
#include <gtest/gtest.h>

int main(int argc, char** argv) {
    std::cout << "Running main() from main.cpp" << std::endl;
    ::testing::InitGoogleMock(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new TestEnvironment);
    return RUN_ALL_TESTS();
}