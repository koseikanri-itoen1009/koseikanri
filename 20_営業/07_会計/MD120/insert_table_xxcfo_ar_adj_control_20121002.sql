-- �C���Ǘ��e�[�u���̓o�^�i�ڍs�p�����f�[�^�j
INSERT INTO xxcfo_ar_adj_control(
   business_date          -- �Ɩ����t
  ,adjustment_id          -- �C��ID
  ,process_flag           -- �����σt���O
  ,created_by             -- �쐬��
  ,creation_date          -- �쐬��
  ,last_updated_by        -- �ŏI�X�V��
  ,last_update_date       -- �ŏI�X�V��
  ,last_update_login      -- �ŏI�X�V���O�C��
  ,request_id             -- �v��ID
  ,program_application_id -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  ,program_id             -- �R���J�����g�E�v���O����ID
  ,program_update_date    -- �v���O�����X�V��
) VALUES (
   SYSDATE
  ,1
  ,'Y'
  ,1
  ,SYSDATE
  ,1
  ,SYSDATE
  ,1
  ,1
  ,1
  ,1
  ,SYSDATE
);
--
COMMIT;
--
