#!/bin/bash

# Define PSQL variable for database queries
# -t: tuples only (no headers)
# --no-align: no column alignment
# -c: execute single command string
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~"
echo -e "\nWelcome to My Salon, how can I help you?\n"

# Function to display services
DISPLAY_SERVICES() {
  # Optional argument $1 can be used for a message before the list
  if [[ $1 ]]
  then
    echo -e "$1"
  fi

  # Fetch and display services: service_id) name
  SERVICES_LIST=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$SERVICES_LIST" | while IFS="|" read SERVICE_ID NAME
  do
    # Use sed to remove leading/trailing spaces that psql might add
    SERVICE_ID_FORMATTED=$(echo $SERVICE_ID | sed 's/^ *| *$//g')
    NAME_FORMATTED=$(echo $NAME | sed 's/^ *| *$//g')
    echo "$SERVICE_ID_FORMATTED) $NAME_FORMATTED"
  done
}

# Display services for the first time
DISPLAY_SERVICES

# Loop until a valid service is selected
while true
do
  # Prompt for service ID
  read SERVICE_ID_SELECTED

  # Check if input is a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # Not a number, show services again with error message
    DISPLAY_SERVICES "\nI could not find that service. What would you like today?"
    continue # Go to next loop iteration
  fi

  # Check if service ID exists in the database
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  # If service name is empty (not found)
  if [[ -z $SERVICE_NAME ]]
  then
    # Show services again with error message
    DISPLAY_SERVICES "\nI could not find that service. What would you like today?"
  else
    # Valid service selected, break the loop
    break
  fi
done

# Clean up potential leading/trailing spaces from SERVICE_NAME
SERVICE_NAME_FORMATTED=$(echo $SERVICE_NAME | sed 's/^ *| *$//g')

# Prompt for phone number
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE

# Check if customer exists
CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

# If customer doesn't exist
if [[ -z $CUSTOMER_NAME ]]
then
  # Prompt for name
  echo -e "\nI don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME

  # Insert new customer
  INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
  # Clean up name formatting just in case (although read usually handles this well)
  CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed 's/^ *| *$//g')
else
  # Customer exists, clean up name formatting
  CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed 's/^ *| *$//g')
fi

# Get customer_id (needed for the appointment)
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

# Prompt for appointment time
echo -e "\nWhat time would you like your $SERVICE_NAME_FORMATTED, $CUSTOMER_NAME_FORMATTED?"
read SERVICE_TIME

# Insert the appointment
INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

# Check if insertion was successful (basic check)
if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
then
  # Output confirmation message
  echo -e "\nI have put you down for a $SERVICE_NAME_FORMATTED at $SERVICE_TIME, $CUSTOMER_NAME_FORMATTED."
fi

# End of script
