-- �����Ǘ��Ǘ��e�[�u���̓o�^�i�ڍs�p�����f�[�^�j
-- �����f�[�^
INSERT INTO xxcfo_ar_cash_control(
    business_date             -- �Ɩ����t
  , control_id                -- �Ǘ�ID
  , trx_type                  -- �^�C�v
  , process_flag              -- �����σt���O
  , created_by                -- �쐬��
  , creation_date             -- �쐬��
  , last_updated_by           -- �ŏI�X�V��
  , last_update_date          -- �ŏI�X�V��
  , last_update_login         -- �ŏI�X�V���O�C��
  , request_id                -- �v��ID
  , program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , program_id                -- �R���J�����g�E�v���O����ID
  , program_update_date       -- �v���O�����X�V��
) VALUES (
    xxccp_common_pkg2.get_process_date
                              -- �Ɩ����t
  , 1                         -- �Ǘ�ID
  , '����'                    -- �^�C�v
  , 'Y'                       -- �����σt���O
  , -1                        -- �쐬��
  , SYSDATE                   -- �쐬��
  , -1                        -- �ŏI�X�V��
  , SYSDATE                   -- �ŏI�X�V��
  , NULL                      -- �ŏI�X�V���O�C��
  , NULL                      -- �v��ID
  , NULL                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , NULL                      -- �R���J�����g�E�v���O����ID
  , NULL                      -- �v���O�����X�V��
);
-- �����f�[�^
INSERT INTO xxcfo_ar_cash_control(
    business_date             -- �Ɩ����t
  , control_id                -- �Ǘ�ID
  , trx_type                  -- �^�C�v
  , process_flag              -- �����σt���O
  , created_by                -- �쐬��
  , creation_date             -- �쐬��
  , last_updated_by           -- �ŏI�X�V��
  , last_update_date          -- �ŏI�X�V��
  , last_update_login         -- �ŏI�X�V���O�C��
  , request_id                -- �v��ID
  , program_application_id    -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , program_id                -- �R���J�����g�E�v���O����ID
  , program_update_date       -- �v���O�����X�V��
) VALUES (
    xxccp_common_pkg2.get_process_date
                              -- �Ɩ����t
  , 1                         -- �Ǘ�ID
  , '����'                    -- �^�C�v
  , 'Y'                       -- �����σt���O
  , -1                        -- �쐬��
  , SYSDATE                   -- �쐬��
  , -1                        -- �ŏI�X�V��
  , SYSDATE                   -- �ŏI�X�V��
  , NULL                      -- �ŏI�X�V���O�C��
  , NULL                      -- �v��ID
  , NULL                      -- �R���J�����g�E�v���O�����E�A�v���P�[�V����ID
  , NULL                      -- �R���J�����g�E�v���O����ID
  , NULL                      -- �v���O�����X�V��
);
--
COMMIT;
--