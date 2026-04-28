# This controller handles exporting data from the application to various formats.
class ExportController < ApplicationController
  SUPPORTED_EXPORT_CLASSES = {
    "User" => User,
    "Team" => Team,
    "CourseParticipant" => CourseParticipant,
    "AssignmentParticipant" => AssignmentParticipant,
    "ProjectTopic" => ProjectTopic,
    "Questionnaire" => Questionnaire,
    "Item" => Item,
    "QuestionAdvice" => QuestionAdvice
  }.freeze

  before_action :export_params

  def resolve_export_class(name)
    SUPPORTED_EXPORT_CLASSES[name.to_s]
  end

  def index
    klass = resolve_export_class(params[:class])
    raise ArgumentError, "Unsupported export class: #{params[:class]}" if klass.nil?
    
    render json: export_metadata_for(klass), status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def export
    # Parse ordered fields from JSON, if provided
    ordered_fields =
      begin
        JSON.parse(params[:ordered_fields]) if params[:ordered_fields]
      rescue JSON::ParserError
        render json: { error: "Invalid JSON for ordered_fields" }, status: :unprocessable_entity
        return
      end

    klass = resolve_export_class(params[:class])
    raise ArgumentError, "Unsupported export class: #{params[:class]}" if klass.nil?
    
    csv_file = if klass == Team
                 Team.with_assignment_context(params[:assignment_id]) do
                   Export.perform(klass, ordered_fields)
                 end
               elsif klass == AssignmentParticipant
                 # AssignmentParticipant export should include only the
                 # participants for the selected assignment.
                 AssignmentParticipant.with_assignment_context(params[:assignment_id], current_user) do
                   Export.perform(klass, ordered_fields)
                 end
               elsif klass == CourseParticipant
                 # CourseParticipant export should include only the
                 # participants for the selected course.
                 CourseParticipant.with_course_context(params[:course_id], current_user) do
                   Export.perform(klass, ordered_fields)
                 end
               elsif klass == ProjectTopic
                 ProjectTopic.with_assignment_context(params[:assignment_id]) do
                   Export.perform(klass, ordered_fields)
                 end
               else
                 Export.perform(klass, ordered_fields)
               end

    render json: {
      message: "#{params[:class]} has been exported!",
      file: csv_file
    }, status: :ok

  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def export_params
    params.permit(:class, :ordered_fields, :assignment_id, :course_id)
  end

  def export_metadata_for(klass)
    # The participant CSV intentionally exposes username only. Other user
    # details are previewed from the users table but not exported as input.
    if klass == AssignmentParticipant
      AssignmentParticipant.with_assignment_context(params[:assignment_id], current_user) do
        return {
          mandatory_fields: klass.mandatory_fields,
          optional_fields: klass.optional_fields,
          external_fields: klass.external_fields
        }
      end
    end

    if klass == CourseParticipant
      CourseParticipant.with_course_context(params[:course_id], current_user) do
        return {
          mandatory_fields: klass.mandatory_fields,
          optional_fields: klass.optional_fields,
          external_fields: klass.external_fields
        }
      end
    end

    if klass == Team
      Team.with_assignment_context(params[:assignment_id]) do
        return {
          mandatory_fields: klass.mandatory_fields,
          optional_fields: klass.optional_fields,
          external_fields: klass.external_fields
        }
      end
    end

    if klass == ProjectTopic
      ProjectTopic.with_assignment_context(params[:assignment_id]) do
        return {
          mandatory_fields: klass.mandatory_fields,
          optional_fields: klass.optional_fields,
          external_fields: klass.external_fields
        }
      end
    end

    {
      mandatory_fields: klass.mandatory_fields,
      optional_fields: klass.optional_fields,
      external_fields: klass.external_fields
    }
  end
end
