-- �������p�Ǘ��e�[�u���̓o�^�i�ڍs�p�����f�[�^�j
INSERT INTO xxcfo_deprn_control(
    set_of_books_id           -- ��v����ID
  , period_name               -- ��v����
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
    2001                      -- ��v����ID
  , '2012-12'                 -- ��v����
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