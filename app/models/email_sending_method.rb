class EmailSendingMethod
def accept(visitor)
    raise NotImplementedError, 'This method should be implemented by the subclass'
  end
end