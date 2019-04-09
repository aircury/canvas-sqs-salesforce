from canvasapi import Canvas as OriginalCanvas
from canvasapi.quiz import QuizSubmission, Quiz
from canvasapi.assignment import Assignment
from canvasapi.submission import Submission
from canvasapi.util import combine_kwargs

import os
import logging

class Canvas(OriginalCanvas):
    def get_quiz_submission(self, course, quiz, submission, **kwargs):
        uri_str = 'courses/{}/quizzes/{}/submissions/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, quiz, submission),
            _kwargs=combine_kwargs(**kwargs)
        )

        return (
            QuizSubmission(self.__requester, response.json()['quiz_submissions'][0]),
            Quiz(self.__requester, response.json()['quizzes'][0])
        )
    
    def get_submission(self, course, assignment, user):
        uri_str = 'courses/{}/assignments/{}/submissions/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, assignment, user),
            _kwargs=combine_kwargs(**kwargs)
        )

        return Submission(self.__requester, response.json())

    def get_assignment(self, course, assignment):
        uri_str = 'courses/{}/assignments/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, assignment),
            _kwargs=combine_kwargs(**kwargs)
        )

        return Assignment(self.__requester, response.json())


canvas = Canvas(os.environ['CANVAS_URL'], os.environ['CANVAS_TOKEN'])

EVENT_MAP = {
    # type: action: object->type: canvas_event
    'AssessmentEvent': {'Submitted': {'Attempt':             'quiz_submitted'}},
    'AssignableEvent': {'Submitted': {'Attempt':             'submission_created'},
                        'Submitted': {'Modified':            'submission_modified'}},
    'SessionEvent':    {'LoggedIn':  {'SoftwareApplication': 'logged_in'},
                        'LoggedOut': {'SoftwareApplication': 'logged_out'}},
}

def process_quiz_submitted(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    user = canvas.get_user(user_id)
    uid = user.sis_user_id
    course_id = group['extensions']['com.instructure.canvas']['entity_id']
    course = canvas.get_course(course_id)
    quiz_id = objectv['assignable']['id'].split(':')[-1]
    submission_id = objectv['extensions']['com.instructure.canvas']['entity_id']
    submission, quiz = canvas.get_quiz_submission(course_id, quiz_id, submission_id, include='quiz')
    detail = '<participant> submitted the quiz "%s" from programme "%s" with score %s/%s on <date>' % \
        (quiz.title, course.name, submission.score, submission.quiz_points_possible)
    activity = 'Quiz Submitted'

    return (uid, detail, activity)

def process_submission_created(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    user = canvas.get_user(user_id)
    uid = user.sis_user_id
    course_id = group['extensions']['com.instructure.canvas']['entity_id']
    course = canvas.get_course(course_id)
    assignment_id = objectv['assignable']['id'].split(':')[-1]
    assignment = canvas.get_assignment(course_id, assignment_id)
    submission = canvas.get_submission(course_id, assignment_id, user.id)
    detail = '<participant> created submission for the assignment "%s" from programme "%s" with grade %s on <date>' % \
        (assignment.name, course.name, submission.grade)
    activity = 'Submission Created'

    return (uid, detail, activity)

def process_submission_updated(actor, objectv, group):
    uid, detail, activity = process_submission_created(actor, objectv, group)

    return (uid, detail.replace('created submission', 'updated submission'), activity.replace('Created', 'Updated'))

def process_logged_in(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    detail = '<participant> logged in on <date>'
    activity = 'Logged In'

    return (uid, detail, activity)

def process_logged_out(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    detail = '<participant> logged out on <date>'
    activity = 'Logged Out'

    return (uid, detail, activity)

