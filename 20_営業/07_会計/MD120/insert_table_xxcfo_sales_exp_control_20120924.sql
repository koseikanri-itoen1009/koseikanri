DECLARE
  --==============================================================
  -- �̔����ъǗ��e�[�u�������f�[�^����
  --==============================================================
  lt_sales_exp_header_id                xxcos_sales_exp_headers.sales_exp_header_id%TYPE;
  --
BEGIN
  BEGIN
    SELECT    MAX(xseh.sales_exp_header_id)       sales_exp_header_id
    INTO      lt_sales_exp_header_id
    FROM      xxcos_sales_exp_headers   xseh
    ;
  END;
  -- �̔����ъǗ��e�[�u���̓o�^�i�ڍs�p�����f�[�^�j
  INSERT INTO xxcfo_sales_exp_control(
      business_date             -- �Ɩ����t
    , sales_exp_header_id       -- �̔����уw�b�_ID
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
    , lt_sales_exp_header_id    -- �̔����уw�b�_ID
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
END ;
/
--
