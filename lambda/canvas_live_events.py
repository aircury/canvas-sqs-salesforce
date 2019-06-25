from canvasapi import Canvas as OriginalCanvas
from canvasapi.quiz import QuizSubmission, Quiz
from canvasapi.assignment import Assignment
from canvasapi.submission import Submission
from canvasapi.enrollment import Enrollment
from canvasapi.canvas_object import CanvasObject
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
    
    def get_submission(self, course, assignment, user, **kwargs):
        uri_str = 'courses/{}/assignments/{}/submissions/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, assignment, user),
            _kwargs=combine_kwargs(**kwargs)
        )

        return Submission(self.__requester, response.json())

    def get_assignment(self, course, assignment, **kwargs):
        uri_str = 'courses/{}/assignments/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, assignment),
            _kwargs=combine_kwargs(**kwargs)
        )

        return Assignment(self.__requester, response.json())

    def get_discussion(self, course, id, **kwargs):
        uri_str = 'courses/{}/discussion_topics/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(course, id),
            _kwargs=combine_kwargs(**kwargs)
        )

        return CanvasObject(self.__requester, response.json())

    def get_enrollment(self, id, **kwargs):
        uri_str = 'accounts/1/enrollments/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(id),
            _kwargs=combine_kwargs(**kwargs)
        )

        return Enrollment(self.__requester, response.json())

    def get_role(self, id, **kwargs):
        uri_str = 'accounts/1/roles/{}'

        response = self.__requester.request(
            'GET',
            uri_str.format(id),
            _kwargs=combine_kwargs(**kwargs)
        )

        return CanvasObject(self.__requester, response.json())

canvas = Canvas(os.environ['CANVAS_URL'], os.environ['CANVAS_TOKEN'])

EVENT_MAP = {
    # https://github.com/instructure/canvas-lms/blob/3afdafe5ae246d22bcaaa841bd63c036853c075d/doc/api/caliper_live_events.md#event-mapping inverse
    # type: action: object->type: canvas_event
    'AssessmentEvent': {'Submitted': {'Attempt':             'quiz_submitted'}},
    'AssignableEvent': {'Submitted': {'Attempt':             'submission_created'}},
    'ThreadEvent':     {'Created':   {'Thread':              'discussion_topic_created'}},
    'MessageEvent':    {'Posted':    {'Message':             'discussion_entry_created'}},
    'Event':           {'Created':   {'Entity':              'enrollment_created'},
                        'Modified':  {'Entity':              'enrollment_updated',
                                      'Attempt':             'submission_updated'}},
    'SessionEvent':    {'LoggedIn':  {'SoftwareApplication': 'logged_in'},
                        'LoggedOut': {'SoftwareApplication': 'logged_out'}},
}

# For example "1367000000000001480" is "1480" in Salesforce
def clean_course_id(id):
    return id[5:].lstrip('0')

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

    return (uid, clean_course_id(course_id), detail, activity, quiz.title)

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

    return (uid, clean_course_id(course_id), detail, activity, assignment.name)

def process_submission_updated(actor, objectv, group):
    uid, course_id, detail, activity, event_name = process_submission_created(actor, objectv, group)

    return (uid, course_id, detail.replace('created submission', 'updated submission'), activity.replace('Created', 'Updated'), event_name)

def process_discussion_topic_created(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    discussion = objectv['name']
    course_id = group['extensions']['com.instructure.canvas']['entity_id']
    detail = '<participant> created the discussion "%s" on <date>' % discussion
    activity = 'Discussion Created'

    return (uid, course_id, detail, activity, None)

def process_discussion_entry_created(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    discussion_id = objectv['isPartOf']['id'].split(':')[-1]
    course_id = group['extensions']['com.instructure.canvas']['entity_id']
    discussion = canvas.get_discussion(course_id, discussion_id)
    detail = '<participant> replied to the discussion "%s" on <date>' % discussion.title
    activity = 'Discussion Replied'

    return (uid, clean_course_id(course_id), detail, activity, None)

def process_enrollment_created(actor, objectv, group):
    uid, course_id, detail, activity, event_name = process_enrollment_updated(actor, objectv, group)

    return (uid, course_id, detail, activity.replace('Updated', 'Created'), event_name)

def process_enrollment_updated(actor, objectv, group):
    enrollment_id = objectv['extensions']['com.instructure.canvas']['entity_id']
    enrollment = canvas.get_enrollment(enrollment_id)
    state = enrollment.enrollment_state
    role = canvas.get_role(enrollment.role_id)
    uid = enrollment.sis_user_id
    course = canvas.get_course(enrollment.course_id)
    detail = '<participant> status "%s" for role "%s" on programme "%s" on <date>' % (state, role.label, course.name)
    activity = 'Enrollment Updated'

    return (uid, enrollment.course_id, detail, activity, None) 

def process_logged_in(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    detail = '<participant> logged in on <date>'
    activity = 'Logged In'

    return (uid, None, detail, activity, None)

def process_logged_out(actor, objectv, group):
    user_id = actor['extensions']['com.instructure.canvas']['entity_id']
    uid = canvas.get_user(user_id).sis_user_id
    detail = '<participant> logged out on <date>'
    activity = 'Logged Out'

    return (uid, None, detail, activity, None)

