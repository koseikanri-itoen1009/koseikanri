CREATE OR REPLACE VIEW APPS.XXCFF_LEASED_OBJECT_V
AS 
SELECT xoh.object_header_id              AS object_header_id           -- ���������h�c
     , xoh.object_code                   AS object_code                -- �����R�[�h
     , xoh.lease_class                   AS lease_class_code           -- ���[�X��ʃR�[�h
     ,(SELECT xlcv.lease_class_name
       FROM   xxcff_lease_class_v          xlcv
       WHERE  xoh.lease_class = xlcv.lease_class_code) AS lease_class_name           -- ���[�X��ʖ���
     , xoh.department_code               AS department_code            -- �Ǘ�����R�[�h
     ,(SELECT xdv.department_name
       FROM   xxcff_department_v           xdv
       WHERE  xoh.department_code = xdv.department_code) AS department_name           -- �Ǘ����喼��
     , xoh.object_status                AS object_status_code         -- �����X�e�[�^�X�R�[�h
     ,(SELECT xosv.object_status_name
       FROM   xxcff_object_status_v        xosv
       WHERE  xoh.object_status = xosv.object_status_code) AS object_status_name           -- �����X�e�[�^�X����
     , xoh.manufacturer_name             AS manufacturer_name          -- ���[�J�[��
     , xoh.age_type                      AS age_type                   -- �N��
     , xoh.model                         AS model                      -- �@��
     , xoh.serial_number                 AS serial_number              -- �@��
     , xoh.chassis_number                AS chassis_number             -- �ԑ�ԍ�
     , xctmp.lease_company_code          AS lease_company_code         -- ���[�X��ЃR�[�h
     , xctmp.lease_company_name          AS lease_company_name         -- ���[�X��Ж���
     , xctmp.contract_number             AS contract_number            -- �_��ԍ�
     , xctmp.contract_line_id            AS contract_line_id           -- �_�񖾍ד���ID
     , xctmp.contract_line_num           AS contract_line_num          -- �}��
     , xctmp.lease_kind_code             AS lease_kind_code            -- ���[�X��ރR�[�h
     , xctmp.lease_kind_name             AS lease_kind_name            -- ���[�X��ޖ���
     , xoh.lease_type                    AS lease_type_code            -- ���[�X�敪�R�[�h
     ,(SELECT xltv.lease_type_name
       FROM   xxcff_lease_type_v           xltv
       WHERE  xoh.lease_type = xltv.lease_type_code) AS lease_type_name           -- ���[�X�敪����
     , xctmp.contract_status_code        AS contract_status_code       -- �_��X�e�[�^�X�R�[�h
     , xctmp.contract_status_name        AS contract_status_name       -- �_��X�e�[�^�X����
     , xoh.re_lease_times                AS re_lease_times             -- �ă��[�X��
     , xoh.re_lease_flag                 AS re_lease_flag_code         -- �ă��[�X�v�t���O�R�[�h
     ,(SELECT xrlfv.re_lease_flag_name
       FROM   xxcff_re_lease_flag_v        xrlfv
       WHERE  xoh.re_lease_flag = xrlfv.re_lease_flag_code) AS re_lease_flag_name           -- �ă��[�X�v�t���O����
     , xctmp.contract_date               AS contract_date              -- ���[�X�_���
     , xctmp.lease_start_date            AS lease_start_date           -- ���[�X�J�n��
     , xctmp.lease_end_date              AS lease_end_date             -- ���[�X�I����
     , xoh.cancellation_date             AS cancellation_date          -- ���r����
     , xoh.bond_acceptance_flag          AS bond_acceptance_flag_code  -- �؏���̃t���O�R�[�h
     ,(SELECT xbafv.bond_acceptance_flag_name
       FROM   xxcff_bond_acceptance_flag_v xbafv
       WHERE  xoh.bond_acceptance_flag = xbafv.bond_acceptance_flag_code) AS bond_acceptance_flag_name           -- �؏���̃t���O����
     , xoh.expiration_date               AS expiration_date            -- ������
     , xoh.owner_company                AS owner_company_code         -- �{�ЍH��R�[�h
     ,(SELECT xocv.owner_company_name
       FROM   xxcff_owner_company_v        xocv
       WHERE  xoh.owner_company = xocv.owner_company_code) AS owner_company_name           -- �{�ЍH�ꖼ��
     , xoh.active_flag                     AS active_flag_code           -- �L���t���O�R�[�h
     ,(SELECT xafv.active_flag_name
       FROM   xxcff_active_flag_v          xafv
       WHERE  xoh.active_flag = xafv.active_flag_code) AS active_flag_name           -- �L���t���O
     , xctmp.estimated_cash_price        AS estimated_cash_price       -- �w�����z
     , xctmp.second_total_charge         AS second_total_charge        -- ���z���[�X��
     , xctmp.second_total_deduction      AS second_total_deduction     -- ���z�T���z
     , xctmp.gross_total_charge          AS gross_total_charge         -- ���[�X�����z
     , xoh.created_by                    AS created_by                 -- �쐬��
     , xoh.creation_date                 AS creation_date              -- �쐬��
     , xoh.last_updated_by               AS last_updated_by            -- �ŏI�X�V��
     , xoh.last_update_date              AS last_update_date           -- �ŏI�X�V��
     , xoh.last_update_login             AS last_update_login          -- �ŏI�X�V���O�C��
FROM   xxcff_object_headers         xoh
     , (SELECT  temp.contract_number        AS contract_number         -- �_��ԍ�
              , temp.contract_date          AS contract_date           -- ���[�X�_���
              , temp.lease_start_date       AS lease_start_date        -- ���[�X�J�n��
              , temp.lease_end_date         AS lease_end_date          -- ���[�X�I����
              , temp.contract_line_id       AS contract_line_id        -- �_�񖾍ד���ID
              , temp.contract_line_num      AS contract_line_num       -- ���הԍ�
              , temp.object_header_id       AS object_header_id        -- ��������ID
              , temp.expiration_date        AS expiration_date         -- ������
              , temp.estimated_cash_price   AS estimated_cash_price    -- ���ό����w�����z
              , temp.second_total_charge    AS second_total_charge     -- 2��ڈȍ~�v_���[�X��
              , temp.second_total_deduction AS second_total_deduction  -- 2��ڈȍ~�v_�T���z
              , temp.gross_total_charge     AS gross_total_charge      -- ���z�v_���[�X��
              , temp.lease_company          AS lease_company_code      -- ���[�X��ЃR�[�h
              ,(SELECT xlcv.lease_company_name
                FROM   xxcff_lease_company_v    xlcv
                WHERE  temp.lease_company = xlcv.lease_company_code) AS lease_company_name      -- ���[�X��Ж�
              , temp.lease_kind               AS lease_kind_code         -- ���[�X��ރR�[�h
              ,(SELECT xlkv.lease_kind_name
                FROM   xxcff_lease_kind_v       xlkv
                WHERE  temp.lease_kind = xlkv.lease_kind_code) AS lease_kind_name         -- ���[�X��ޖ�
              , temp.contract_status   AS contract_status_code    -- �_��X�e�[�^�X�R�[�h
              ,(SELECT xcsv.contract_status_name
                FROM   xxcff_contract_status_v  xcsv
                WHERE  temp.contract_status = xcsv.contract_status_code) AS contract_status_name    -- �_��X�e�[�^�X��
        FROM   (SELECT  RANK() OVER( partition BY xcl.object_header_id
                                     ORDER     BY xch.re_lease_times DESC
                               )                     AS ranking  -- ��������ID�P�ʂōă��[�X�񐔂̍~���ɍ̔�
                       , xch.contract_number         AS contract_number         -- �_��ԍ�
                       , xch.contract_date           AS contract_date           -- ���[�X�_���
                       , xch.lease_start_date        AS lease_start_date        -- ���[�X�J�n��
                       , xch.lease_end_date          AS lease_end_date          -- ���[�X�I����
                       , xcl.contract_line_id        AS contract_line_id        -- �_�񖾍ד���ID
                       , xcl.contract_line_num       AS contract_line_num       -- ���הԍ�
                       , xcl.second_total_charge     AS second_total_charge     -- 2��ڈȍ~�v_���[�X��
                       , xcl.second_total_deduction  AS second_total_deduction  -- 2��ڈȍ~�v_�T���z
                       , xcl.gross_total_charge      AS gross_total_charge      -- ���z�v_���[�X��
                       , xcl.estimated_cash_price    AS estimated_cash_price    -- ���ό����w�����z
                       , xcl.object_header_id        AS object_header_id        -- ��������ID
                       , xcl.expiration_date         AS expiration_date         -- ������
                       , xch.lease_company           AS lease_company           -- ���[�X���
                       , xcl.lease_kind              AS lease_kind              -- ���[�X���
                       , xcl.contract_status         AS contract_status         -- �_��X�e�[�^�X
                 FROM    xxcff_contract_headers  xch   -- ���[�X�_��
                       , xxcff_contract_lines    xcl   -- ���[�X�_�񖾍�
                 WHERE   xch.contract_header_id = xcl.contract_header_id  -- �_�����ID
                )                        temp  -- �_��
        WHERE   temp.ranking         = 1    -- �ŐV�̌_�񖾍�
       )                            xctmp  -- �_��֘A
WHERE  xoh.object_header_id     = xctmp.object_header_id(+)  -- ��������ID

