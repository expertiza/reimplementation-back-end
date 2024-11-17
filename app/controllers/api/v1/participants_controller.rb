class Api::V1::ParticipantsController < ApplicationController
  # Return a list of participants
  # GET /participants
  def index; end

  # Return a specified participant
  # GET /participants/:id
  def show; end

  # Copy all participants from a course to an assignment
  # GET /participants/inherit
  def inherit; end

  # Copy all participants from an assignment to a course
  # GET /participants/bequeath
  def bequeath; end

  # Create a participant
  # POST /participants
  def create; end

  # Update the permissions of a participant
  # PATCH /participants/:id/authorization
  def update_authorization; end

  # Update the handle of a participant
  # PATCH /participants/:id/handle
  def update_handle; end

  # Delete a specified participant
  # DELETE /participants/:id
  def destroy; end
end
