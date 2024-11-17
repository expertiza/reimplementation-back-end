class Api::V1::ParticipantsController < ApplicationController
  # Return a list of participants
  # GET /participants
  def index; end

  # Return a specified participant
  # GET /participant/:id
  def show; end

  # Copy all participants from a course to an assignment
  # GET /participants/inherit
  def inherit; end

  # Copy all participants from an assignment to a course
  # GET /participants/bequeath
  def bequeath; end

  # Create a participant
  # POST /participant
  def create; end

  # Update the permissions of a participant
  # PATCH /participant/:id/authorization
  def update_authorization; end

  # Update the handle of a participant
  # PATCH /participant/:id/handle
  def update_handle; end

  # Delete a specified participant
  # DELETE /participant/:id
  def destroy; end
end
