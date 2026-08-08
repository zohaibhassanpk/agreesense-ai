#!/bin/bash

set -e

echo "======================================"
echo "   AgriSenseAI - Test Suite Runner"
echo "======================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

total_passed=0
total_failed=0

run_test() {
    local test_file=$1
    local test_name=$2

    echo "----------------------------------------"
    echo "Testing: $test_name"
    echo "File: $test_file"
    echo "----------------------------------------"

    output=$(flutter test "$test_file" --no-pub 2>&1 || true)

    if echo "$output" | grep -q "All tests passed!"; then
        count=$(echo "$output" | grep -oE '\+[0-9]+' | tail -1 | tr -d '+')
        count=${count:-0}
        echo -e "${GREEN}PASS${NC} - $count tests"
        total_passed=$((total_passed + count))
        return 0
    elif echo "$output" | grep -q "Some tests failed"; then
        passed=$(echo "$output" | grep -oE '\+[0-9]+' | tail -1 | tr -d '+')
        failed=$(echo "$output" | grep -oE '\-[0-9]+' | tail -1 | tr -d '-')
        passed=${passed:-0}
        failed=${failed:-1}
        echo -e "${RED}FAIL${NC} - $passed passed, $failed failed"
        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
        return 1
    else
        echo -e "${YELLOW}UNKNOWN${NC}"
        echo "$output" | tail -20
        total_failed=$((total_failed + 1))
        return 2
    fi
}

echo "PHASE 1: SPLASH ONBOARDING"
run_test "test/features/splash_onboarding/domain/onboarding_domain_test.dart" "Onboarding Domain"
run_test "test/features/splash_onboarding/data/onboarding_data_test.dart" "Onboarding Data"
run_test "test/features/splash_onboarding/presentation/providers/onboarding_provider_test.dart" "Onboarding Provider"
run_test "test/features/splash_onboarding/presentation/widgets/onboarding_widgets_test.dart" "Onboarding Widgets"

echo ""
echo "PHASE 2: AUTH"
run_test "test/features/auth/domain/auth_domain_test.dart" "Auth Domain"
run_test "test/features/auth/data/auth_data_test.dart" "Auth Data"
run_test "test/features/auth/presentation/providers/auth_provider_test.dart" "Auth Provider"
run_test "test/features/auth/presentation/widgets/auth_widgets_test.dart" "Auth Widgets"

echo ""
echo "PHASE 3: HOME"
run_test "test/features/home/domain/home_domain_test.dart" "Home Domain"
run_test "test/features/home/data/home_data_test.dart" "Home Data"
run_test "test/features/home/presentation/providers/home_provider_test.dart" "Home Provider"
run_test "test/features/home/presentation/widgets/home_widgets_test.dart" "Home Widgets"

echo ""
echo "PHASE 4: ALERTS"
run_test "test/features/alerts/domain/alerts_domain_test.dart" "Alerts Domain"
run_test "test/features/alerts/data/alerts_data_test.dart" "Alerts Data"
run_test "test/features/alerts/presentation/providers/alerts_provider_test.dart" "Alerts Provider"
run_test "test/features/alerts/presentation/widgets/alerts_widgets_test.dart" "Alerts Widgets"

echo ""
echo "PHASE 5: ANALYTICS"
run_test "test/features/analytics/domain/analytics_domain_test.dart" "Analytics Domain"
run_test "test/features/analytics/data/analytics_data_test.dart" "Analytics Data"
run_test "test/features/analytics/presentation/providers/analytics_provider_test.dart" "Analytics Provider"
run_test "test/features/analytics/presentation/widgets/analytics_widgets_test.dart" "Analytics Widgets"

echo ""
echo "PHASE 6: SETTINGS"
run_test "test/features/settings/domain/settings_domain_test.dart" "Settings Domain"
run_test "test/features/settings/data/settings_data_test.dart" "Settings Data"
run_test "test/features/settings/presentation/providers/settings_provider_test.dart" "Settings Provider"
run_test "test/features/settings/presentation/widgets/settings_widgets_test.dart" "Settings Widgets"

echo ""
echo "PHASE 7: PROFILE"
run_test "test/features/profile/domain/profile_domain_test.dart" "Profile Domain"
run_test "test/features/profile/data/profile_data_test.dart" "Profile Data"
run_test "test/features/profile/presentation/providers/profile_provider_test.dart" "Profile Provider"
run_test "test/features/profile/presentation/widgets/profile_widgets_test.dart" "Profile Widgets"

echo ""
echo "PHASE 8: INTEGRATION"
if flutter devices | grep -q "No devices"; then
  echo -e "${YELLOW}Skipping integration tests: no supported device connected.${NC}"
else
  run_test "integration_test/features/splash_onboarding/splash_onboarding_integration_test.dart" "Onboarding Integration"
  run_test "integration_test/features/auth/auth_integration_test.dart" "Auth Integration"
  run_test "integration_test/features/home/home_integration_test.dart" "Home Integration"
  run_test "integration_test/features/alerts/alerts_integration_test.dart" "Alerts Integration"
  run_test "integration_test/features/analytics/analytics_integration_test.dart" "Analytics Integration"
  run_test "integration_test/features/settings/settings_integration_test.dart" "Settings Integration"
  run_test "integration_test/features/profile/profile_integration_test.dart" "Profile Integration"
fi

echo ""
echo "======================================"
echo "FINAL TEST RESULTS"
echo "======================================"
echo -e "${GREEN}Total Passed: $total_passed${NC}"
echo -e "${RED}Total Failed: $total_failed${NC}"
echo "Total Tests: $((total_passed + total_failed))"

if [ $total_failed -eq 0 ]; then
  echo -e "${GREEN}ALL TESTS PASSED${NC}"
  exit 0
else
  echo -e "${RED}SOME TESTS FAILED${NC}"
  exit 1
fi
