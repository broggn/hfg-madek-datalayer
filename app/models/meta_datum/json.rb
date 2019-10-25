class MetaDatum::JSON < MetaDatum::Text

  def value
    json
  end

  def value=(new_value)
    self.json = new_value
  end

end
