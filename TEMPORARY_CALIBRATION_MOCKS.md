# Temporary Calibration Mocks

The following temporary "mock" functionality has been implemented in the backend to unblock frontend testing for calibration assignments. These mocks simulate team submissions and instructor "Gold Standard" reviews, which are currently missing their respective editors.

## 1. Mock Team Submissions
- **Location**: `app/controllers/calibration_response_maps_controller.rb` in the `create` action.
- **Behavior**: When an instructor adds a participant for calibration, if the team doesn't have any submitted hyperlinks, a default link (`https://github.com/expertiza/reimplementation`) is added.
- **Purpose**: Allows the "Submitted items(s)" column in the Assignment Editor and the "Submitted artifacts" section in the Calibration Report to display data.

## 2. Mock Gold Standard Reviews
- **Location**: `app/controllers/calibration_response_maps_controller.rb` in the `begin` action.
- **Behavior**: When the instructor clicks the "Begin" link for a calibration participant, the backend checks if a response already exists. If not, it automatically creates a completed `Response` and populates `Answer` records for all scored rubric items with the maximum possible score.
- **Purpose**: 
    - Transitions the review status from "Begin" to "View/Edit" in the Assignment Editor.
    - Provides a "Gold Standard" reference for the comparison charts in the Calibration Report view.

## Identification in Code
All temporary code is wrapped in blocks clearly marked with:
`# START: TEMPORARY MOCK ...`
and
`# END: TEMPORARY MOCK ...`

## Removal Instructions
Once the actual Review Editor and Submission UI are implemented, these blocks should be removed from `app/controllers/calibration_response_maps_controller.rb`.
