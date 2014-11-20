CREATE OR REPLACE PACKAGE XXCFF_COMMON3_PKG
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCFF_COMMON3_PKG(spec)
 * Description      : ���[�X�����֘A���ʊ֐�
 * MD.050           : �Ȃ�
 * Version          : 1.0
 *
 * Program List
 * --------------------      ---- ----- --------------------------------------------------
 *  Name                     Type  Ret   Description
 * --------------------      ---- ----- --------------------------------------------------
 *  insert_ob_hed             P           ���[�X�����o�^�֐�
 *  insert_ob_his             P           ���[�X��������o�^�֐�
 *  update_ob_hed             P           ���[�X�����X�V�֐�
 *  update_ob_his             P           ���[�X���������X�V�֐�
 *  create_contract_ass       P           �_��֘A����
 *  create_ob_det             P           ���[�X�������쐬
 *  create_ob_bat             P           ���[�X�������쐬�i�o�b�`�j
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008-11-13   1.0    SCS �A���^���l   �V�K�쐬
 *
 *****************************************************************************************/
--
--#######################  ���R�[�h�^�錾�� START   #######################
--
  -- �������
  TYPE object_data_rtype IS RECORD(
     object_header_id        xxcff_object_headers.object_header_id%TYPE           -- ��������ID
   , object_code             xxcff_object_headers.object_code%TYPE                -- �����R�[�h
   , lease_class             xxcff_object_headers.lease_class%TYPE                -- ���[�X���
   , lease_type              xxcff_object_headers.lease_type%TYPE DEFAULT 1       -- ���[�X�敪
   , re_lease_times          xxcff_object_headers.re_lease_times%TYPE DEFAULT 0   -- �ă��[�X��
   , po_number               xxcff_object_headers.po_number%TYPE                  -- �����ԍ�
   , registration_number     xxcff_object_headers.registration_number%TYPE        -- �o�^�ԍ�
   , age_type                xxcff_object_headers.age_type%TYPE                   -- �N��
   , model                   xxcff_object_headers.model%TYPE                      -- �@��
   , serial_number           xxcff_object_headers.serial_number%TYPE              -- �@��
   , quantity                xxcff_object_headers.quantity%TYPE                   -- ����
   , manufacturer_name       xxcff_object_headers.manufacturer_name%TYPE          -- ���[�J�[��
   , department_code         xxcff_object_headers.department_code%TYPE            -- �Ǘ�����R�[�h
   , owner_company           xxcff_object_headers.owner_company%TYPE              -- �{�Ё^�H��
   , installation_address    xxcff_object_headers.installation_address%TYPE       -- ���ݒu�ꏊ
   , installation_place      xxcff_object_headers.installation_place%TYPE         -- ���ݒu��
   , chassis_number          xxcff_object_headers.chassis_number%TYPE             -- �ԑ�ԍ�
   , re_lease_flag           xxcff_object_headers.re_lease_flag%TYPE DEFAULT 0    -- �ă��[�X�v�t���O
   , cancellation_type       xxcff_object_headers.cancellation_type%TYPE          -- ���敪
   , cancellation_date       xxcff_object_headers.cancellation_date%TYPE          -- ���r����
   , dissolution_date        xxcff_object_headers.dissolution_date%TYPE           -- ���r���L�����Z����
   , bond_acceptance_flag    xxcff_object_headers.bond_acceptance_flag%TYPE DEFAULT 0 -- �؏���̃t���O
   , bond_acceptance_date    xxcff_object_headers.bond_acceptance_date%TYPE       -- �؏���̓�
   , expiration_date         xxcff_object_headers.expiration_date%TYPE            -- ������
   , object_status           xxcff_object_headers.object_status%TYPE              -- �����X�e�[�^�X
   , active_flag             xxcff_object_headers.active_flag%TYPE DEFAULT 'Y'    -- �����L���t���O
   , info_sys_if_date        xxcff_object_headers.info_sys_if_date%TYPE           -- ���[�X�Ǘ����A�g��
   , generation_date         xxcff_object_headers.generation_date%TYPE            -- ������
   , customer_code           xxcff_object_headers.customer_code%TYPE DEFAULT NULL -- �ڋq�R�[�h
   , created_by              xxcff_object_headers.created_by%TYPE                 -- �쐬��
   , creation_date           xxcff_object_headers.creation_date%TYPE              -- �쐬��
   , last_updated_by         xxcff_object_headers.last_updated_by%TYPE            -- �ŏI�X�V��
   , last_update_date        xxcff_object_headers.last_update_date%TYPE           -- �ŏI�X�V��
   , last_update_login       xxcff_object_headers.last_update_login%TYPE          -- �ŏI�X�V۸޲�
   , request_id              xxcff_object_headers.request_id%TYPE                 -- �v��ID
   , program_application_id  xxcff_object_headers.program_application_id%TYPE     -- �ݶ��ĥ��۸��ѥ���ع����ID
   , program_id              xxcff_object_headers.program_id%TYPE                 -- �ݶ��ĥ��۸���ID
   , program_update_date     xxcff_object_headers.program_update_date%TYPE        -- ��۸��эX�V��
   , m_owner_company         xxcff_object_histories.m_owner_company%TYPE          -- �ړ����{�ЍH��
   , m_department_code       xxcff_object_histories.m_department_code%TYPE        -- �ړ����Ǘ�����
   , m_installation_address  xxcff_object_histories.m_installation_address%TYPE   -- �ړ������ݒu�ꏊ
   , m_installation_place    xxcff_object_histories.m_installation_place%TYPE     -- �ړ������ݒu��
   , m_registration_number   xxcff_object_histories.m_registration_number%TYPE    -- �ړ����o�^�ԍ�
   , description             xxcff_object_histories.description%TYPE              -- �E�v
  );
  --
  --#######################  �e�[�u���^�錾�� START   #######################
  --
  --#######################  �v���V�[�W���錾�� START   #######################
  --
  --
  -- ���[�X�����o�^�֐�
  PROCEDURE insert_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X��������o�^�֐�
  PROCEDURE insert_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�����X�V�֐�
  PROCEDURE update_ob_hed(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X���������X�V�֐�
  PROCEDURE update_ob_his(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�������쐬
  PROCEDURE create_ob_det(
    iv_exce_mode           IN        VARCHAR2,           -- �������[�h
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
  -- ���[�X�������쐬�i�o�b�`�j
  PROCEDURE create_ob_bat(
    io_object_data_rec IN OUT NOCOPY object_data_rtype,  -- �������
    ov_errbuf             OUT NOCOPY VARCHAR2,           -- �G���[�E���b�Z�[�W
    ov_retcode            OUT NOCOPY VARCHAR2,           -- ���^�[���E�R�[�h
    ov_errmsg             OUT NOCOPY VARCHAR2            -- ���[�U�[�E�G���[�E���b�Z�[�W
  );
  --
--
END XXCFF_COMMON3_PKG
;
/
