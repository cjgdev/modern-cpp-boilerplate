#define private public
#define protected public
#include "placeholder.hpp"
#undef protected
#undef private

#include "test_common.hpp"

class placeholder_test : public ::testing::Test {
protected:
    virtual void SetUp() override {
        instance = make_unique<placeholder>();
    }
    virtual void TearDown() override {
        delete strategy.release();
    }
    unique_ptr<placeholder> instance;
};

TEST_F(placeholder_test, rename_me){
    EXPECT_TRUE(false);
}