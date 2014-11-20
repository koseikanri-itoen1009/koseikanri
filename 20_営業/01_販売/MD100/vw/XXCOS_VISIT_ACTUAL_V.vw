/************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * View Name       : xxcos_visit_actual_v
 * Description     : �L���K����уr���[�i�̔��j
 * Version         : 1.1
 *
 * Change Record
 * ------------- ----- ---------------- ---------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- ---------------------------------
 *  2010/12/14    1.0  K.Kiriu          �V�K�쐬
 *  2011/07/14    1.17 K.Kubo           [E_�{�ғ�_07885]�Ή� PT�Ή��i�^�X�N���2�������o�����j
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcos_visit_actual_v
(
   task_id
  ,created_by
  ,creation_date
  ,last_updated_by
  ,last_update_date
  ,last_update_login
  ,object_version_number
  ,task_number
  ,task_type_id
  ,task_status_id
  ,task_priority_id
  ,owner_id
  ,owner_type_code
  ,owner_territory_id
  ,assigned_by_id
  ,cust_account_id
  ,customer_id
  ,address_id
  ,planned_start_date
  ,planned_end_date
  ,scheduled_start_date
  ,scheduled_end_date
  ,actual_start_date
  ,actual_end_date
  ,source_object_type_code
  ,timezone_id
  ,source_object_id
  ,source_object_name
  ,duration
  ,duration_uom
  ,planned_effort
  ,planned_effort_uom
  ,actual_effort
  ,actual_effort_uom
  ,percentage_complete
  ,reason_code
  ,private_flag
  ,publish_flag
  ,restrict_closure_flag
  ,multi_booked_flag
  ,milestone_flag
  ,holiday_flag
  ,billable_flag
  ,bound_mode_code
  ,soft_bound_flag
  ,workflow_process_id
  ,notification_flag
  ,notification_period
  ,notification_period_uom
  ,parent_task_id
  ,recurrence_rule_id
  ,alarm_start
  ,alarm_start_uom
  ,alarm_on
  ,alarm_count
  ,alarm_fired_count
  ,alarm_interval
  ,alarm_interval_uom
  ,deleted_flag
  ,palm_flag
  ,wince_flag
  ,laptop_flag
  ,device1_flag
  ,device2_flag
  ,device3_flag
  ,costs
  ,currency_code
  ,org_id
  ,escalation_level
  ,attribute1
  ,attribute2
  ,attribute3
  ,attribute4
  ,attribute5
  ,attribute6
  ,attribute7
  ,attribute8
  ,attribute9
  ,attribute10
  ,attribute11
  ,attribute12
  ,attribute13
  ,attribute14
  ,attribute15
  ,attribute_category
  ,security_group_id
  ,orig_system_reference
  ,orig_system_reference_id
  ,update_status_flag
  ,calendar_start_date
  ,calendar_end_date
  ,date_selected
  ,template_id
  ,template_group_id
  ,object_changed_date
  ,task_confirmation_status
  ,task_confirmation_counter
  ,task_split_flag
  ,open_flag
  ,entity
  ,child_position
  ,child_sequence_num
  ,party_id
)
AS
SELECT jtb.task_id                     task_id
      ,jtb.created_by                  created_by
      ,jtb.creation_date               creation_date
      ,jtb.last_updated_by             last_updated_by
      ,jtb.last_update_date            last_update_date
      ,jtb.last_update_login           last_update_login
      ,jtb.object_version_number       object_version_number
      ,jtb.task_number                 task_number
      ,jtb.task_type_id                task_type_id
      ,jtb.task_status_id              task_status_id
      ,jtb.task_priority_id            task_priority_id
      ,jtb.owner_id                    owner_id
      ,jtb.owner_type_code             owner_type_code
      ,jtb.owner_territory_id          owner_territory_id
      ,jtb.assigned_by_id              assigned_by_id
      ,jtb.cust_account_id             cust_account_id
      ,jtb.customer_id                 customer_id
      ,jtb.address_id                  address_id
      ,jtb.planned_start_date          planned_start_date
      ,jtb.planned_end_date            planned_end_date
      ,jtb.scheduled_start_date        scheduled_start_date
      ,jtb.scheduled_end_date          scheduled_end_date
      ,jtb.actual_start_date           actual_start_date
      ,jtb.actual_end_date             actual_end_date
      ,jtb.source_object_type_code     source_object_type_code
      ,jtb.timezone_id                 timezone_id
      ,jtb.source_object_id            source_object_id
      ,jtb.source_object_name          source_object_name
      ,jtb.duration                    duration
      ,jtb.duration_uom                duration_uom
      ,jtb.planned_effort              planned_effort
      ,jtb.planned_effort_uom          planned_effort_uom
      ,jtb.actual_effort               actual_effort
      ,jtb.actual_effort_uom           actual_effort_uom
      ,jtb.percentage_complete         percentage_complete
      ,jtb.reason_code                 reason_code
      ,jtb.private_flag                private_flag
      ,jtb.publish_flag                publish_flag
      ,jtb.restrict_closure_flag       restrict_closure_flag
      ,jtb.multi_booked_flag           multi_booked_flag
      ,jtb.milestone_flag              milestone_flag
      ,jtb.holiday_flag                holiday_flag
      ,jtb.billable_flag               billable_flag
      ,jtb.bound_mode_code             bound_mode_code
      ,jtb.soft_bound_flag             soft_bound_flag
      ,jtb.workflow_process_id         workflow_process_id
      ,jtb.notification_flag           notification_flag
      ,jtb.notification_period         notification_period
      ,jtb.notification_period_uom     notification_period_uom
      ,jtb.parent_task_id              parent_task_id
      ,jtb.recurrence_rule_id          recurrence_rule_id
      ,jtb.alarm_start                 alarm_start
      ,jtb.alarm_start_uom             alarm_start_uom
      ,jtb.alarm_on                    alarm_on
      ,jtb.alarm_count                 alarm_count
      ,jtb.alarm_fired_count           alarm_fired_count
      ,jtb.alarm_interval              alarm_interval
      ,jtb.alarm_interval_uom          alarm_interval_uom
      ,jtb.deleted_flag                deleted_flag
      ,jtb.palm_flag                   palm_flag
      ,jtb.wince_flag                  wince_flag
      ,jtb.laptop_flag                 laptop_flag
      ,jtb.device1_flag                device1_flag
      ,jtb.device2_flag                device2_flag
      ,jtb.device3_flag                device3_flag
      ,jtb.costs                       costs
      ,jtb.currency_code               currency_code
      ,jtb.org_id                      org_id
      ,jtb.escalation_level            escalation_level
      ,jtb.attribute1                  attribute1
      ,jtb.attribute2                  attribute2
      ,jtb.attribute3                  attribute3
      ,jtb.attribute4                  attribute4
      ,jtb.attribute5                  attribute5
      ,jtb.attribute6                  attribute6
      ,jtb.attribute7                  attribute7
      ,jtb.attribute8                  attribute8
      ,jtb.attribute9                  attribute9
      ,jtb.attribute10                 attribute10
      ,jtb.attribute11                 attribute11
      ,jtb.attribute12                 attribute12
      ,jtb.attribute13                 attribute13
      ,jtb.attribute14                 attribute14
      ,jtb.attribute15                 attribute15
      ,jtb.attribute_category          attribute_category
      ,jtb.security_group_id           security_group_id
      ,jtb.orig_system_reference       orig_system_reference
      ,jtb.orig_system_reference_id    orig_system_reference_id
      ,jtb.update_status_flag          update_status_flag
      ,jtb.calendar_start_date         calendar_start_date
      ,jtb.calendar_end_date           calendar_end_date
      ,jtb.date_selected               date_selected
      ,jtb.template_id                 template_id
      ,jtb.template_group_id           template_group_id
      ,jtb.object_changed_date         object_changed_date
      ,jtb.task_confirmation_status    task_confirmation_status
      ,jtb.task_confirmation_counter   task_confirmation_counter
      ,jtb.task_split_flag             task_split_flag
      ,jtb.open_flag                   open_flag
      ,jtb.entity                      entity
      ,jtb.child_position              child_position
      ,jtb.child_sequence_num          child_sequence_num
      ,jtb.source_object_id            party_id
FROM   xxcos_jtf_tasks_b jtb  --�^�X�N�e�[�u��
WHERE  jtb.source_object_type_code   = 'PARTY'
AND    NVL(jtb.deleted_flag, 'N')    = 'N'
UNION ALL
SELECT /*+ leading(ala) index(jtb2 XXCOS_JTF_TASKS_B_N02) */
       jtb2.task_id                    task_id
      ,jtb2.created_by                 created_by
      ,jtb2.creation_date              creation_date
      ,jtb2.last_updated_by            last_updated_by
      ,jtb2.last_update_date           last_update_date
      ,jtb2.last_update_login          last_update_login
      ,jtb2.object_version_number      object_version_number
      ,jtb2.task_number                task_number
      ,jtb2.task_type_id               task_type_id
      ,jtb2.task_status_id             task_status_id
      ,jtb2.task_priority_id           task_priority_id
      ,jtb2.owner_id                   owner_id
      ,jtb2.owner_type_code            owner_type_code
      ,jtb2.owner_territory_id         owner_territory_id
      ,jtb2.assigned_by_id             assigned_by_id
      ,jtb2.cust_account_id            cust_account_id
      ,jtb2.customer_id                customer_id
      ,jtb2.address_id                 address_id
      ,jtb2.planned_start_date         planned_start_date
      ,jtb2.planned_end_date           planned_end_date
      ,jtb2.scheduled_start_date       scheduled_start_date
      ,jtb2.scheduled_end_date         scheduled_end_date
      ,jtb2.actual_start_date          actual_start_date
      ,jtb2.actual_end_date            actual_end_date
      ,jtb2.source_object_type_code    source_object_type_code
      ,jtb2.timezone_id                timezone_id
      ,jtb2.source_object_id           source_object_id
      ,jtb2.source_object_name         source_object_name
      ,jtb2.duration                   duration
      ,jtb2.duration_uom               duration_uom
      ,jtb2.planned_effort             planned_effort
      ,jtb2.planned_effort_uom         planned_effort_uom
      ,jtb2.actual_effort              actual_effort
      ,jtb2.actual_effort_uom          actual_effort_uom
      ,jtb2.percentage_complete        percentage_complete
      ,jtb2.reason_code                reason_code
      ,jtb2.private_flag               private_flag
      ,jtb2.publish_flag               publish_flag
      ,jtb2.restrict_closure_flag      restrict_closure_flag
      ,jtb2.multi_booked_flag          multi_booked_flag
      ,jtb2.milestone_flag             milestone_flag
      ,jtb2.holiday_flag               holiday_flag
      ,jtb2.billable_flag              billable_flag
      ,jtb2.bound_mode_code            bound_mode_code
      ,jtb2.soft_bound_flag            soft_bound_flag
      ,jtb2.workflow_process_id        workflow_process_id
      ,jtb2.notification_flag          notification_flag
      ,jtb2.notification_period        notification_period
      ,jtb2.notification_period_uom    notification_period_uom
      ,jtb2.parent_task_id             parent_task_id
      ,jtb2.recurrence_rule_id         recurrence_rule_id
      ,jtb2.alarm_start                alarm_start
      ,jtb2.alarm_start_uom            alarm_start_uom
      ,jtb2.alarm_on                   alarm_on
      ,jtb2.alarm_count                alarm_count
      ,jtb2.alarm_fired_count          alarm_fired_count
      ,jtb2.alarm_interval             alarm_interval
      ,jtb2.alarm_interval_uom         alarm_interval_uom
      ,jtb2.deleted_flag               deleted_flag
      ,jtb2.palm_flag                  palm_flag
      ,jtb2.wince_flag                 wince_flag
      ,jtb2.laptop_flag                laptop_flag
      ,jtb2.device1_flag               device1_flag
      ,jtb2.device2_flag               device2_flag
      ,jtb2.device3_flag               device3_flag
      ,jtb2.costs                      costs
      ,jtb2.currency_code              currency_code
      ,jtb2.org_id                     org_id
      ,jtb2.escalation_level           escalation_level
      ,jtb2.attribute1                 attribute1
      ,jtb2.attribute2                 attribute2
      ,jtb2.attribute3                 attribute3
      ,jtb2.attribute4                 attribute4
      ,jtb2.attribute5                 attribute5
      ,jtb2.attribute6                 attribute6
      ,jtb2.attribute7                 attribute7
      ,jtb2.attribute8                 attribute8
      ,jtb2.attribute9                 attribute9
      ,jtb2.attribute10                attribute10
      ,jtb2.attribute11                attribute11
      ,jtb2.attribute12                attribute12
      ,jtb2.attribute13                attribute13
      ,jtb2.attribute14                attribute14
      ,jtb2.attribute15                attribute15
      ,jtb2.attribute_category         attribute_category
      ,jtb2.security_group_id          security_group_id
      ,jtb2.orig_system_reference      orig_system_reference
      ,jtb2.orig_system_reference_id   orig_system_reference_id
      ,jtb2.update_status_flag         update_status_flag
      ,jtb2.calendar_start_date        calendar_start_date
      ,jtb2.calendar_end_date          calendar_end_date
      ,jtb2.date_selected              date_selected
      ,jtb2.template_id                template_id
      ,jtb2.template_group_id          template_group_id
      ,jtb2.object_changed_date        object_changed_date
      ,jtb2.task_confirmation_status   task_confirmation_status
      ,jtb2.task_confirmation_counter  task_confirmation_counter
      ,jtb2.task_split_flag            task_split_flag
      ,jtb2.open_flag                  open_flag
      ,jtb2.entity                     entity
      ,jtb2.child_position             child_position
      ,jtb2.child_sequence_num         child_sequence_num
      ,ala.customer_id                 party_id
FROM   xxcos_jtf_tasks_b   jtb2  --�^�X�N�e�[�u��
      ,as_leads_all  ala   --���k�e�[�u��
WHERE  jtb2.source_object_type_code = 'OPPORTUNITY'
AND    NVL(jtb2.deleted_flag, 'N')  = 'N'
AND    ala.lead_id                  = jtb2.source_object_id
WITH READ ONLY
;
COMMENT ON COLUMN xxcos_visit_actual_v.task_id                   IS '�^�X�NID';
COMMENT ON COLUMN xxcos_visit_actual_v.created_by                IS '�쐬��';
COMMENT ON COLUMN xxcos_visit_actual_v.creation_date             IS '�쐬��';
COMMENT ON COLUMN xxcos_visit_actual_v.last_updated_by           IS '�ŏI�X�V��';
COMMENT ON COLUMN xxcos_visit_actual_v.last_update_date          IS '�ŏI�X�V��';
COMMENT ON COLUMN xxcos_visit_actual_v.last_update_login         IS '�ŏI�X�V���O�C��';
COMMENT ON COLUMN xxcos_visit_actual_v.object_version_number     IS '�I�u�W�F�N�g�o�[�W�����ԍ�';
COMMENT ON COLUMN xxcos_visit_actual_v.task_number               IS '�^�X�N�ԍ�';
COMMENT ON COLUMN xxcos_visit_actual_v.task_type_id              IS '�^�X�N�^�C�vID';
COMMENT ON COLUMN xxcos_visit_actual_v.task_status_id            IS '�^�X�N�X�e�[�^�XID';
COMMENT ON COLUMN xxcos_visit_actual_v.task_priority_id          IS '�^�X�N�D��ID';
COMMENT ON COLUMN xxcos_visit_actual_v.owner_id                  IS '���L��ID';
COMMENT ON COLUMN xxcos_visit_actual_v.owner_type_code           IS '���L�҃^�C�v�R�[�h';
COMMENT ON COLUMN xxcos_visit_actual_v.owner_territory_id        IS '���L�ҋ��ID';
COMMENT ON COLUMN xxcos_visit_actual_v.assigned_by_id            IS '������ID';
COMMENT ON COLUMN xxcos_visit_actual_v.cust_account_id           IS '�A�J�E���gID';
COMMENT ON COLUMN xxcos_visit_actual_v.customer_id               IS '�ڋqID';
COMMENT ON COLUMN xxcos_visit_actual_v.address_id                IS '�A�h���XID';
COMMENT ON COLUMN xxcos_visit_actual_v.planned_start_date        IS '�v��J�n��';
COMMENT ON COLUMN xxcos_visit_actual_v.planned_end_date          IS '�v��I����';
COMMENT ON COLUMN xxcos_visit_actual_v.scheduled_start_date      IS '�\��J�n��';
COMMENT ON COLUMN xxcos_visit_actual_v.scheduled_end_date        IS '�\��I����';
COMMENT ON COLUMN xxcos_visit_actual_v.actual_start_date         IS '���ъJ�n��';
COMMENT ON COLUMN xxcos_visit_actual_v.actual_end_date           IS '���яI����';
COMMENT ON COLUMN xxcos_visit_actual_v.source_object_type_code   IS '�\�[�X�I�u�W�F�N�g�^�C�v�R�[�h';
COMMENT ON COLUMN xxcos_visit_actual_v.timezone_id               IS '����ID';
COMMENT ON COLUMN xxcos_visit_actual_v.source_object_id          IS '�\�[�X�I�u�W�F�N�gID';
COMMENT ON COLUMN xxcos_visit_actual_v.source_object_name        IS '�\�[�X�I�u�W�F�N�g��';
COMMENT ON COLUMN xxcos_visit_actual_v.duration                  IS '����';
COMMENT ON COLUMN xxcos_visit_actual_v.duration_uom              IS '�����P��';
COMMENT ON COLUMN xxcos_visit_actual_v.planned_effort            IS '�����v��';
COMMENT ON COLUMN xxcos_visit_actual_v.planned_effort_uom        IS '�����v��P��';
COMMENT ON COLUMN xxcos_visit_actual_v.actual_effort             IS '��������';
COMMENT ON COLUMN xxcos_visit_actual_v.actual_effort_uom         IS '�������ђP��';
COMMENT ON COLUMN xxcos_visit_actual_v.percentage_complete       IS '�i����';
COMMENT ON COLUMN xxcos_visit_actual_v.reason_code               IS '���R�R�[�h';
COMMENT ON COLUMN xxcos_visit_actual_v.private_flag              IS '�v���C�x�[�g�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.publish_flag              IS '���s�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.restrict_closure_flag     IS '�������t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.multi_booked_flag         IS '�}���`�\��t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.milestone_flag            IS '�}�C���X�g�[���t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.holiday_flag              IS '�x���t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.billable_flag             IS '�����\�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.bound_mode_code           IS '�o�E���h���[�h�R�[�h';
COMMENT ON COLUMN xxcos_visit_actual_v.soft_bound_flag           IS '�\�t�g�o�E���h�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.workflow_process_id       IS '���[�N�t���[�v���Z�XID';
COMMENT ON COLUMN xxcos_visit_actual_v.notification_flag         IS '�ʒm�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.notification_period       IS '�ʒm����';
COMMENT ON COLUMN xxcos_visit_actual_v.notification_period_uom   IS '�ʒm���ԒP��';
COMMENT ON COLUMN xxcos_visit_actual_v.parent_task_id            IS '�e�^�X�NID';
COMMENT ON COLUMN xxcos_visit_actual_v.recurrence_rule_id        IS '�Ĕ��K��ID';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_start               IS '�x���J�n';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_start_uom           IS '�x���J�n�P��';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_on                  IS '�x����';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_count               IS '�x���J�E���g';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_fired_count         IS '���ٌx���J�E���g';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_interval            IS '�x���Ԋu';
COMMENT ON COLUMN xxcos_visit_actual_v.alarm_interval_uom        IS '�x���Ԋu�P��';
COMMENT ON COLUMN xxcos_visit_actual_v.deleted_flag              IS '�폜�σt���O';
COMMENT ON COLUMN xxcos_visit_actual_v.palm_flag                 IS '�G���t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.wince_flag                IS '�E�B���X�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.laptop_flag               IS '���b�v�g�b�v�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.device1_flag              IS '�f�o�C�X�P';
COMMENT ON COLUMN xxcos_visit_actual_v.device2_flag              IS '�f�o�C�X�Q';
COMMENT ON COLUMN xxcos_visit_actual_v.device3_flag              IS '�f�o�C�X�R';
COMMENT ON COLUMN xxcos_visit_actual_v.costs                     IS '�o��';
COMMENT ON COLUMN xxcos_visit_actual_v.currency_code             IS '�ʉ݃R�[�h';
COMMENT ON COLUMN xxcos_visit_actual_v.org_id                    IS '�g�DID';
COMMENT ON COLUMN xxcos_visit_actual_v.escalation_level          IS '�G�X�J���[�V�������x��';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute1                IS '�K��敪�P';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute2                IS '�K��敪�Q';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute3                IS '�K��敪�R';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute4                IS '�K��敪�S';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute5                IS '�K��敪�T';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute6                IS '�K��敪�U';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute7                IS '�K��敪�V';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute8                IS '�K��敪�W';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute9                IS '�K��敪�X';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute10               IS '�K��敪�P�O';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute11               IS '�L���K��敪';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute12               IS '�o�^���敪';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute13               IS '�o�^���\�[�X�ԍ�';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute14               IS '�ڋq�X�e�[�^�X';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute15               IS '';
COMMENT ON COLUMN xxcos_visit_actual_v.attribute_category        IS '��������';
COMMENT ON COLUMN xxcos_visit_actual_v.security_group_id         IS '�Z�L�����e�B�O���[�vID';
COMMENT ON COLUMN xxcos_visit_actual_v.orig_system_reference     IS '�I���W�i���V�X�e�����t�@�����X';
COMMENT ON COLUMN xxcos_visit_actual_v.orig_system_reference_id  IS '�I���W�i���V�X�e�����t�@�����XID';
COMMENT ON COLUMN xxcos_visit_actual_v.update_status_flag        IS '�X�e�[�^�X�X�V�t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.calendar_start_date       IS '�J�����_�[�J�n��';
COMMENT ON COLUMN xxcos_visit_actual_v.calendar_end_date         IS '�J�����_�[�I����';
COMMENT ON COLUMN xxcos_visit_actual_v.date_selected             IS '�I���';
COMMENT ON COLUMN xxcos_visit_actual_v.template_id               IS '�e���v���[�gID';
COMMENT ON COLUMN xxcos_visit_actual_v.template_group_id         IS '�e���v���[�g�O���[�vID';
COMMENT ON COLUMN xxcos_visit_actual_v.object_changed_date       IS '�I�u�W�F�N�g�ύX��';
COMMENT ON COLUMN xxcos_visit_actual_v.task_confirmation_status  IS '�^�X�N�m�F�J�n';
COMMENT ON COLUMN xxcos_visit_actual_v.task_confirmation_counter IS '�^�X�N�m�F�J�E���^�[';
COMMENT ON COLUMN xxcos_visit_actual_v.task_split_flag           IS '�^�X�N�����t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.open_flag                 IS '�I�[�v���t���O';
COMMENT ON COLUMN xxcos_visit_actual_v.entity                    IS '����';
COMMENT ON COLUMN xxcos_visit_actual_v.child_position            IS '�q�|�W�V����';
COMMENT ON COLUMN xxcos_visit_actual_v.child_sequence_num        IS '�q�V�[�P���X�ԍ�';
COMMENT ON COLUMN xxcos_visit_actual_v.party_id                  IS '�p�[�e�B�[ID';

COMMENT ON TABLE xxcos_visit_actual_v IS '�L���K����уr���[�i�̔��j';
