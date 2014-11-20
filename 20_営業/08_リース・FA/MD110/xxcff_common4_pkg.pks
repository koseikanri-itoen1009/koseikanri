create or replace PACKAGE XXCFF_COMMON4_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : xxcff_common4_pkg(spec)
 * Description      : ���[�X�_��֘A���ʊ֐�
 * MD.050           : �Ȃ�
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_co_hed             P           ���[�X�_��o�^�֐�
 *  insert_co_lin             P           ���[�X�_�񖾍דo�^�֐�
 *  insert_co_his             P           ���[�X�_�񗚗�o�^�֐�
 *  update_co_hed             P           ���[�X�_��X�V�֐�
 *  update_co_lin             P           ���[�X�_�񖾍׍X�V�֐�
 *
 *  Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-19    1.0   SCS�E��S��       �V�K�쐬
 *  2008-12-22    1.0   SCS�E��S��       �ŋ��R�[�h��ǉ�
 *
 *****************************************************************************************/
--
--#######################  ���R�[�h�^�錾�� START   #######################
--
  -- ���[�X�_����
  TYPE cont_hed_data_rtype IS RECORD(
     contract_header_id         xxcff_contract_headers.contract_header_id%TYPE         -- �_�����ID
   , contract_number            xxcff_contract_headers.contract_number%TYPE            -- �_��ԍ�
   , lease_class                xxcff_contract_headers.lease_class%TYPE                -- ���[�X���
   , lease_type                 xxcff_contract_headers.lease_type%TYPE                 -- ���[�X�敪
   , lease_company              xxcff_contract_headers.lease_company%TYPE              -- ���[�X���
   , re_lease_times             xxcff_contract_headers.re_lease_times%TYPE DEFAULT 0   -- �ă��[�X��
   , comments                   xxcff_contract_headers.comments%TYPE                   -- ����
   , contract_date              xxcff_contract_headers.contract_date%TYPE              -- ���[�X�_���
   , payment_frequency          xxcff_contract_headers.payment_frequency%TYPE          -- �x����
   , payment_type               xxcff_contract_headers.payment_type%TYPE               -- �p�x
   , payment_years              xxcff_contract_headers.payment_years%TYPE              -- �N�x
   , lease_start_date           xxcff_contract_headers.lease_start_date%TYPE           -- ���[�X�J�n��
   , lease_end_date             xxcff_contract_headers.lease_end_date%TYPE             -- ���[�X�I����
   , first_payment_date         xxcff_contract_headers.first_payment_date%TYPE         -- ����x����
   , second_payment_date        xxcff_contract_headers.second_payment_date%TYPE        -- �Q��ڎx����
   , third_payment_date         xxcff_contract_headers.third_payment_date%TYPE         -- �R��ڈȍ~�x����
   , start_period_name          xxcff_contract_headers.start_period_name%TYPE          -- ��p�v���v��v����   
   , lease_payment_flag         xxcff_contract_headers.lease_payment_flag%TYPE         -- �x���v�抮���t���O
   , tax_code                   xxcff_contract_headers.tax_code%TYPE                   -- �ŃR�[�h
   , created_by                 xxcff_contract_headers.created_by%TYPE                 -- �쐬��
   , creation_date              xxcff_contract_headers.creation_date%TYPE              -- �쐬��
   , last_updated_by            xxcff_contract_headers.last_updated_by%TYPE            -- �ŏI�X�V��
   , last_update_date           xxcff_contract_headers.last_update_date%TYPE           -- �ŏI�X�V��
   , last_update_login          xxcff_contract_headers.last_update_login%TYPE          -- �ŏI�X�V۸޲�
   , request_id                 xxcff_contract_headers.request_id%TYPE                 -- �v��ID
   , program_application_id     xxcff_contract_headers.program_application_id%TYPE     -- �ݶ��ĥ��۸��ѥ���ع����ID
   , program_id                 xxcff_contract_headers.program_id%TYPE                 -- �ݶ��ĥ��۸���ID
   , program_update_date        xxcff_contract_headers.program_update_date%TYPE        -- ��۸��эX�V��
  );
  --    
  -- ���[�X�_�񖾍׏��
  TYPE cont_lin_data_rtype IS RECORD(
     contract_line_id           xxcff_contract_lines.contract_line_id%TYPE             -- �_���������ID
   , contract_header_id         xxcff_contract_lines.contract_header_id%TYPE           -- �_�����ID
   , contract_line_num          xxcff_contract_lines.contract_line_num%TYPE            -- �_��}��
   , contract_status            xxcff_contract_lines.contract_status%TYPE              -- �_��X�e�[�^�X
   , first_charge               xxcff_contract_lines.first_charge%TYPE                 -- ���񌎊z���[�X��_���[�X��
   , first_tax_charge           xxcff_contract_lines.first_tax_charge%TYPE             -- �������Ŋz_���[�X��
   , first_total_charge         xxcff_contract_lines.first_total_charge%TYPE           -- ����v���[�X��
   , second_charge              xxcff_contract_lines.second_charge%TYPE                -- �Q��ڌ��z���[�X��_���[�X��
   , second_tax_charge          xxcff_contract_lines.second_tax_charge%TYPE            -- �Q��ڏ���Ŋz_���[�X��
   , second_total_charge        xxcff_contract_lines.second_total_charge%TYPE          -- �Q��ڌv���[�X��
   , first_deduction            xxcff_contract_lines.first_deduction%TYPE              -- ���񌎊z���[�X��_�T���z
   , first_tax_deduction        xxcff_contract_lines.first_tax_deduction%TYPE          -- �������Ŋz_�T���z
   , first_total_deduction      xxcff_contract_lines.first_total_deduction%TYPE        -- ����v�T���z
   , second_deduction           xxcff_contract_lines.second_deduction%TYPE             -- �Q��ڈȍ~���z���[�X��_�T���z
   , second_tax_deduction       xxcff_contract_lines.second_tax_deduction%TYPE         -- �Q��ڈȍ~����Ŋz_�T���z
   , second_total_deduction     xxcff_contract_lines.second_total_deduction%TYPE       -- �Q��ڈȍ~�v�T���z
   , gross_charge               xxcff_contract_lines.gross_charge%TYPE                 -- ���z���[�X��_���[�X��
   , gross_tax_charge           xxcff_contract_lines.gross_tax_charge%TYPE             -- ���z����Ŋz_���[�X��
   , gross_total_charge         xxcff_contract_lines.gross_total_charge%TYPE           -- ���z�v_���[�X��
   , gross_deduction            xxcff_contract_lines.gross_deduction%TYPE              -- ���z���[�X��_�T���z
   , gross_tax_deduction        xxcff_contract_lines.gross_tax_deduction%TYPE          -- ���z�����_�T���z
   , gross_total_deduction      xxcff_contract_lines.gross_total_deduction%TYPE        -- ���z�v_�T���z
   , lease_kind                 xxcff_contract_lines.lease_kind%TYPE                   -- ���[�X���
   , estimated_cash_price       xxcff_contract_lines.estimated_cash_price%TYPE         -- ���ό����w�����z
   , present_value_discount_rate xxcff_contract_lines.present_value_discount_rate%TYPE -- �������l������
   , present_value              xxcff_contract_lines.present_value%TYPE                -- �������l
   , life_in_months             xxcff_contract_lines.life_in_months%TYPE               -- �@��ϗp�N��
   , original_cost              xxcff_contract_lines.original_cost%TYPE                -- �擾���i
   , calc_interested_rate       xxcff_contract_lines.calc_interested_rate%TYPE         -- �v�Z���q��
   , object_header_id           xxcff_contract_lines.object_header_id%TYPE             -- ��������id
   , asset_category             xxcff_contract_lines.asset_category%TYPE               -- ���Y���
   , expiration_date            xxcff_contract_lines.expiration_date%TYPE              -- ������
   , cancellation_date          xxcff_contract_lines.cancellation_date%TYPE            -- ���r����
   , vd_if_date                 xxcff_contract_lines.vd_if_date%TYPE                   -- ���[�X�_����A�g��
   , info_sys_if_date           xxcff_contract_lines.info_sys_if_date%TYPE             -- ���[�X�Ǘ����A�g��
   , first_installation_address xxcff_contract_lines.first_installation_address%TYPE   -- ����ݒu�ꏊ
   , first_installation_place   xxcff_contract_lines.first_installation_place%TYPE     -- ����ݒu��
   , created_by                 xxcff_contract_lines.created_by%TYPE                   -- �쐬��
   , creation_date              xxcff_contract_lines.creation_date%TYPE                -- �쐬��
   , last_updated_by            xxcff_contract_lines.last_updated_by%TYPE              -- �ŏI�X�V��
   , last_update_date           xxcff_contract_lines.last_update_date%TYPE             -- �ŏI�X�V��
   , last_update_login          xxcff_contract_lines.last_update_login%TYPE            -- �ŏI�X�V۸޲�
   , request_id                 xxcff_contract_lines.request_id%TYPE                   -- �v��ID
   , program_application_id     xxcff_contract_lines.program_application_id%TYPE       -- �ݶ��ĥ��۸��ѥ���ع����ID
   , program_id                 xxcff_contract_lines.program_id%TYPE                   -- �ݶ��ĥ��۸���ID
   , program_update_date        xxcff_contract_lines.program_update_date%TYPE          -- ��۸��эX�V��
  );
  --
  -- ���[�X�_�񗚗����
  TYPE cont_his_data_rtype IS RECORD(
     accounting_date            xxcff_contract_histories.accounting_date%TYPE          -- �v���
   , accounting_if_flag         xxcff_contract_histories.accounting_if_flag%TYPE       -- ��vIF�t���O
   , description                xxcff_contract_histories.description%TYPE              -- �E�v
  );
  --
  --#######################  �v���V�[�W���錾�� START   #######################
  --
  --
  -- ���[�X�_��o�^�֐�
  PROCEDURE insert_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- �_����
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�_�񖾍דo�^�֐�
  PROCEDURE insert_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- �_�񖾍׏��
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
 --
  -- ���[�X�_�񗚗�o�^�֐�
  PROCEDURE insert_co_his(
    io_contract_lin_data_rec IN OUT NOCOPY cont_lin_data_rtype   -- �_�񖾍׏��
   ,io_contract_his_data_rec IN OUT NOCOPY cont_his_data_rtype   -- �_�񗚗����
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�_��X�V�֐�
  PROCEDURE update_co_hed(
    io_contract_data_rec    IN OUT NOCOPY cont_hed_data_rtype    -- �_����
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�_�񖾍׍X�V�֐�
  PROCEDURE update_co_lin(
    io_contract_data_rec    IN OUT NOCOPY cont_lin_data_rtype    -- �_�񖾍׏��
   ,ov_errbuf                  OUT NOCOPY VARCHAR2               -- �G���[�E���b�Z�[�W
   ,ov_retcode                 OUT NOCOPY VARCHAR2               -- ���^�[���E�R�[�h
   ,ov_errmsg                  OUT NOCOPY VARCHAR2               -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  --
END XXCFF_COMMON4_PKG
;
/