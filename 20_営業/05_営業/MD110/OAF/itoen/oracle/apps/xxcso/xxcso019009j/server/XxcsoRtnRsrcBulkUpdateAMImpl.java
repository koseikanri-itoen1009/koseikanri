/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateAMImpl
* �T�v����   : ���[�gNo/�S���c�ƈ��ꊇ�X�V��ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.7
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-16 1.0  SCS�x���a��  �V�K�쐬
* 2009-03-05 1.1  SCS�������l  [CT1-034]�d���c�ƈ��G���[�Ή�
* 2009-04-02 1.2  SCS�������  [T1_0092]�S���c�ƈ��̌ڋq�Ή�
* 2009-04-02 1.3  SCS�������  [T1_0125]�S���c�ƈ��̍s�ǉ��Ή�
* 2009-05-07 1.4  SCS�������l  [T1_0603]�o�^�O���؏������@�C��
* 2009-08-19 1.5  SCS�������  [0001123]�ǉ��{�^�������ݒ�Ή�
* 2010-03-23 1.6  SCS�������  [E_�{�ғ�_01942]�Ǘ������_�Ή�
* 2015-09-08 1.7  SCSK�ː��a�K [E_�{�ғ�_13307]���[�g�ꊇ�o�^��ʎd�l�ύX�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.xxcso019009j.util.XxcsoRtnRsrcBulkUpdateConstants;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import oracle.jbo.domain.Date;
// 2009-05-07 [T1_0708] Add Start
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
// 2009-05-07 [T1_0708] Add End


/*******************************************************************************
 * ���[�gNo/�S���c�ƈ��ꊇ�X�V��ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateAMImpl()
  {
  }

  /*****************************************************************************
   * ����������
   * @param mode         �������[�h
   *****************************************************************************
   */
  public void initDetails(
    String mode
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }
    
    rollback();

    if ( ! initVo.isPreparedForExecution() )
    {
      initVo.executeQuery();
    }

    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();

    if ( XxcsoRtnRsrcBulkUpdateConstants.MODE_FIRE_ACTION.equals(mode) )
    {
      XxcsoRtnRsrcBulkUpdateSumVORowImpl sumRow
        = (XxcsoRtnRsrcBulkUpdateSumVORowImpl)sumVo.first();

      initRow.setEmployeeNumber(sumRow.getEmployeeNumber());
      initRow.setFullName(sumRow.getFullName());
      initRow.setRouteNo(sumRow.getRouteNo());
      initRow.setReflectMethod(initRow.getReflectMethod());
      initRow.setAddCustomerButtonRender(Boolean.TRUE);

// 2010-03-23 [E_�{�ғ�_01942] Add Start
      initRow.setBaseCode1(sumRow.getBaseCode());
      initRow.setBaseName(sumRow.getBaseName());
// 2010-03-23 [E_�{�ғ�_01942] Add End

      //�K�p�{�^��������Č�������
      reSearch();

    }
    else
    {
// 2010-03-23 [E_�{�ғ�_01942] Add Start
      initRow.setBaseCode1(initRow.getLoginBaseCode());
      initRow.setBaseName(initRow.getLoginBaseName());
// 2010-03-23 [E_�{�ғ�_01942] Add End
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �i�ރ{�^������������
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

    //////////////////////////////////////
    // �ύX�m�F
    //////////////////////////////////////
    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }
    //////////////////////////////////////
    // �e�s���擾
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
    
    //////////////////////////////////////
    // �����O���؏���
    //////////////////////////////////////
    chkBeforeSearch( txn, initRow );

    //////////////////////////////////////
    // ��������
    //////////////////////////////////////
    sumVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getRouteNo()
// 2010-03-23 [E_�{�ғ�_01942] Add Start
     ,initRow.getBaseCode1()
     ,initRow.getBaseName()
// 2010-03-23 [E_�{�ғ�_01942] Add End
    );
    
    registVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getRouteNo()
// 2010-03-23 [E_�{�ғ�_01942] Add Start
     //,initRow.getBaseCode()
     ,initRow.getBaseCode1()
// 2010-03-23 [E_�{�ғ�_01942] Add End
    );

    // �e�s�̃v���p�e�B�ݒ�
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    
    /* 20090402_abe_T1_0092 START*/
    //if ( registRow != null )
    //{
    /* 20090402_abe_T1_0092 END*/
      initRow.setAddCustomerButtonRender(Boolean.TRUE);
      while ( registRow != null )
      {
        registRow.setAccountNumberReadOnly(Boolean.TRUE);

        registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
      }
    /* 20090402_abe_T1_0092 START*/
    //}
    //else
    //{
    //  initRow.setAddCustomerButtonRender(Boolean.FALSE);
    //}
    /* 20090402_abe_T1_0092 END*/

    //////////////////////////////////////
    // �����㌟�؏���
    //////////////////////////////////////
    List list = chkAfterSearch( txn, registVo );

    if ( list.size() > 0 )
    {
      // �G���[�̏o�͂Ƌ��ɁA�ǉ��{�^�����\��
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
      OAException.raiseBundledOAException( list );
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �ǉ��{�^������������
   *****************************************************************************
   */
  public void handleAddCustomerButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // �v���t�@�C���l�̎擾
    String maxSize = getVoMaxFetchSize( txn );

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

    /* 20090819_abe_0001123 START*/
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }
    /* 20090819_abe_0001123 END*/

    int rowCount = registVo.getRowCount();

    XxcsoUtils.debug(txn, "������������F " + maxSize);
    XxcsoUtils.debug(txn, "�������ʌ����F " + rowCount);

    // �ǉ�����`�F�b�N
    if ( rowCount >= Integer.parseInt(maxSize))
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
         ,XxcsoConstants.TOKEN_OBJECT
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ACCOUNT_INFO
         ,XxcsoConstants.TOKEN_MAX_SIZE
         ,maxSize
        );
    }

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.createRow();

    registRow.setAccountNumberReadOnly(Boolean.FALSE);

    /* 20090819_abe_0001123 START*/
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
    // ������������V�S���A�V���[�gNo��ݒ�
    registRow.setNextResource(initRow.getEmployeeNumber());
    registRow.setNextRouteNo(initRow.getRouteNo());
    /* 20090819_abe_0001123 END*/
    
    registVo.first();
    registVo.insertRow(registRow);

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * �����{�^������������
   *****************************************************************************
   */
  public void handleClearButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    initVo.executeQuery();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �K�p�{�^������������
   *****************************************************************************
   */
  public OAException handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

// 2010-03-23 [E_�{�ғ�_01942] Add Start
    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }
// 2010-03-23 [E_�{�ғ�_01942] Add End
    
    //////////////////////////////////////
    // �e�s���擾
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
// 2010-03-23 [E_�{�ғ�_01942] Add Start
      XxcsoRtnRsrcBulkUpdateSumVORowImpl sumRow
        = (XxcsoRtnRsrcBulkUpdateSumVORowImpl)sumVo.first();
// 2010-03-23 [E_�{�ғ�_01942] Add End
    
    //////////////////////////////////////
    // �o�^�O���؏���
    //////////////////////////////////////
// 2010-03-23 [E_�{�ғ�_01942] Add Start
    //chkBeforeSubmit( txn, initRow,  registVo);
    chkBeforeSubmit( txn, initRow,  sumRow,  registVo);
// 2010-03-23 [E_�{�ғ�_01942] Add End
    //////////////////////////////////////
    // �K�p�J�n������
    //////////////////////////////////////
    Date trgtResourceStartDate = null;
    Date nextResourceStartDate = null;
    Date trgtRouteNoStartDate = null;
    Date nextRouteNoStartDate = null;

    // �u���f���@�v=�������f
    if ( (XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT).equals(
           initRow.getReflectMethod() ) )
    {
      // ���S���K�p�J�n��     :�Ɩ��������t
      trgtResourceStartDate = initRow.getCurrentDate();

      // �����[�gNo�K�p�J�n�� :�Ɩ��������t�̗����P��
      trgtRouteNoStartDate  = initRow.getFirstDate();

      // �V�S���K�p�J�n��     :�Ɩ��������t
      nextResourceStartDate = initRow.getCurrentDate();

      // �V���[�gNo�K�p�J�n�� :�Ɩ��������t�̗����P��
      nextRouteNoStartDate  = initRow.getFirstDate();

    // �u���f���@�v=�\�񔽉f  
    }
    else 
    {
      //���S���K�p�J�n��      :�Ɩ��������t�̗����P��
      trgtResourceStartDate = initRow.getNextDate();

      //�����[�gNo�K�p�J�n��  :�Ɩ��������t�̗����P��
      trgtRouteNoStartDate  = initRow.getNextDate();

      //�V�S���K�p�J�n��      :�Ɩ��������t�̗����P��
      nextResourceStartDate = initRow.getNextDate();

      //�V���[�gNo�K�p�J�n��  :�Ɩ��������t�̗����P��
      nextRouteNoStartDate  = initRow.getNextDate();
    }

    //////////////////////////////////////
    // �o�^�pVO�֓K�p�J�n���ݒ�
    //////////////////////////////////////
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    while ( registRow != null )
    {

      registRow.setTrgtResourceStartDate(trgtResourceStartDate);
      registRow.setTrgtRouteNoStartDate(trgtRouteNoStartDate);
      registRow.setNextResourceStartDate(nextResourceStartDate);
      registRow.setNextRouteNoStartDate(nextRouteNoStartDate);
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }

    //////////////////////////////////////
    // �o�^�E�X�V����
    //////////////////////////////////////
    commit();

    /* 20090402_abe_T1_0125 START*/
    registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    while ( registRow != null )
    {
        //�ǉ��{�^���Ŗ����͂̏ꍇ�͍s���폜
        if ( (( registRow.getNextResource() == null)
          || registRow.getNextResource().equals(""))
          || ((registRow.getNextRouteNo() == null)
          || registRow.getNextRouteNo().equals(""))
        /* 20090819_abe_0001123 START*/
          || ((registRow.getAccountNumber() == null)
          || registRow.getAccountNumber().equals(""))
        /* 20090819_abe_0001123 END*/
          )
        {
          registRow.remove();
        }
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }
    /* 20090402_abe_T1_0125 END*/

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_PROCESS
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_COMPLETE
        ); 
    
    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * ����{�^������������
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    rollback();
    
    XxcsoUtils.debug(txn, "[END]");
  }

    /*****************************************************************************
   * �e�|�b�v���X�g�̏���������
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // ���f���@
    XxcsoLookupListVOImpl appListVo
      = getXxcsoReflectMethodListVO();
    if ( appListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReflectMethodListVO");
    }

    appListVo.initQuery(
      "XXCSO1_REFLECT_METHOD"
     ,"lookup_code"
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �R�~�b�g����
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().commitTransaction(txn);

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N����
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����O���؏���
   * @param txn         OADBTransaction�C���X�^���X
   * @param initRow     �Ώێw�胊�[�W�������
   *****************************************************************************
   */
  private void chkBeforeSearch(
    OADBTransaction txn
   ,XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
  )
  {

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    //��ʍ��ځu���_�b�c�v�K�{�`�F�b�N
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getBaseCode1()
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_BASECODE
         ,0
        );

    //��ʍ��ځu�c�ƈ��R�[�h�v�K�{�`�F�b�N
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getEmployeeNumber()
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_EMPLOYEENUMBER
         ,0
        );

    //��ʍ��ځu���[�gNo�v�Ó����`�F�b�N
    if ( ! chkRouteNo( txn , initRow.getRouteNo() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00046,
            XxcsoConstants.TOKEN_ENTRY,
            XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ROUTENO,
            XxcsoConstants.TOKEN_VALUES,
            initRow.getRouteNo()
          );
      errorList.add(error);
    }
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����㌟�؏���
   * @param txn         OADBTransaction�C���X�^���X
   * @param registVo    �ꊇ�X�V���[�W�������
   * @return �G���[���b�Z�[�W
   *****************************************************************************
   */
  private List chkAfterSearch(
    OADBTransaction        txn
   ,XxcsoRtnRsrcFullVOImpl registVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    // �v���t�@�C���l�̎擾
    String maxSize = getVoMaxFetchSize( txn );

    // �������ʌ����̎擾
    int rowCount = registVo.getRowCount();

    XxcsoUtils.debug(txn, "������������F " + maxSize);
    XxcsoUtils.debug(txn, "�������ʌ����F " + rowCount);

    //���������`�F�b�N
    if ( rowCount > Integer.parseInt( maxSize ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00424
          );
      errorList.add(error);
    }

    // �v���t�@�C���̃G���[���͌������ʂ�\�����A�I��
    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    while ( registRow != null )
    {
      // ���S���A�V�S�������ԏd���ŕ����ݒ肳��Ă��Ȃ����`�F�b�N
      if ( registRow.getTrgtResourceCnt().intValue() > 1 ||
           registRow.getNextResourceCnt().intValue() > 1
      )
      {
        // �d���c�ƈ����݃G���[
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00555
             ,XxcsoConstants.TOKEN_ACCOUNT
             ,registRow.getPartyName()
            );
        errorList.add(error);
      }
      registRow = (XxcsoRtnRsrcFullVORowImpl) registVo.next();
    }

    // �d���G���[���͌������ʂ�S���\�����Ȃ�
    if ( errorList.size() > 0 )
    {
      // 0���ƂȂ錟��������VO��������
      registVo.initQuery(
        ""
       ,""
       ,""
       );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * �o�^�O���؏���
   * @param txn         OADBTransaction�C���X�^���X
   * @param initRow     �Ώێw�胊�[�W�������
   * @param sumRow      �Ώێw�胊�[�W�����r���[���
   * @param registVo    �ꊇ�X�V���[�W�������
   *****************************************************************************
   */
  private void chkBeforeSubmit(
    OADBTransaction                     txn
   ,XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
// 2010-03-23 [E_�{�ғ�_01942] Add Start
   ,XxcsoRtnRsrcBulkUpdateSumVORowImpl  sumRow
// 2010-03-23 [E_�{�ғ�_01942] Add End
   ,XxcsoRtnRsrcFullVOImpl              registVo
  )
  { 
  
    XxcsoUtils.debug(txn, "[START]");
  
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    int index = 0;
// 2010-03-23 [E_�{�ғ�_01942] Add Start
    //String  baseCode      = initRow.getBaseCode();
    String  baseCode      = sumRow.getBaseCode();
// 2010-03-23 [E_�{�ғ�_01942] Add End
    List    coAccountList = new ArrayList();
    boolean isRsvAccount  = false;
    boolean isSameErr     = false;
    
    while ( registRow != null )
    {
      index++;

      //////////////////////////////////////
      // DEBUG���O�o��
      //////////////////////////////////////
      XxcsoUtils.debug(txn, "�ڋq�R�[�h          �F"
                              + registRow.getAccountNumber()                  );
      XxcsoUtils.debug(txn, "�ڋq��              �F"
                              + registRow.getPartyName()                      );
      XxcsoUtils.debug(txn, "�ڋqID              �F"
                              + registRow.getCustAccountId()                  );
      XxcsoUtils.debug(txn, "�쐬��              �F"
                              + registRow.getCreatedBy()                      );
      XxcsoUtils.debug(txn, "�쐬��              �F"
                              + registRow.getCreationDate()                   );
      XxcsoUtils.debug(txn, "�ŏI�X�V��          �F"
                              + registRow.getLastUpdatedBy()                  );
      XxcsoUtils.debug(txn, "�ŏI�X�V��          �F"
                              + registRow.getLastUpdateDate()                 );
      XxcsoUtils.debug(txn, "�ŏI�X�VR           �F"
                              + registRow.getLastUpdateLogin()                );
      XxcsoUtils.debug(txn, "�����[�gNo          �F"
                              + registRow.getTrgtRouteNo()                    );
      XxcsoUtils.debug(txn, "�����[�gNo�K�p�J�n���F"
                              + registRow.getTrgtRouteNoStartDate()           );
      XxcsoUtils.debug(txn, "�����[�gNoEXTID     �F"
                              + registRow.getTrgtRouteNoExtensionId()         );
      XxcsoUtils.debug(txn, "�����[�g�ŏI�X�V��  �F"
                              + registRow.getTrgtRouteNoLastUpdDate()         );
      XxcsoUtils.debug(txn, "�V���[�gNo          �F"
                              + registRow.getNextRouteNo()                    );
      XxcsoUtils.debug(txn, "�V���[�gNo�K�p�J�n���F"
                              + registRow.getNextRouteNoStartDate()           );
      XxcsoUtils.debug(txn, "�V���[�gNoEXTID     �F"
                              + registRow.getNextRouteNoExtensionId()         );
      XxcsoUtils.debug(txn, "�V���[�gNo�ŏI�X�V���F"
                              + registRow.getNextRouteNoLastUpdDate()         );
      XxcsoUtils.debug(txn, "���S��              �F"
                              + registRow.getTrgtResource()                   );
      XxcsoUtils.debug(txn, "���S���K�p�J�n��    �F"
                              + registRow.getTrgtResourceStartDate()          );
      XxcsoUtils.debug(txn, "���S��EXTID         �F"
                              + registRow.getTrgtResourceExtensionId()        );
      XxcsoUtils.debug(txn, "���S���ŏI�X�V��    �F"
                              + registRow.getTrgtResourceLastUpdDate()        );
      XxcsoUtils.debug(txn, "�V�S��              �F"
                              + registRow.getNextResource()                   );
      XxcsoUtils.debug(txn, "�V�S���K�p�J�n��    �F"
                              + registRow.getNextResourceStartDate()          );
      XxcsoUtils.debug(txn, "�V�S��EXTID         �F"
                              + registRow.getNextResourceExtensionId()        );
      XxcsoUtils.debug(txn, "�V�S���ŏI�X�V��    �F"
                              + registRow.getNextResourceLastUpdDate()        );
      XxcsoUtils.debug(txn, "READONLY            �F"
                              + registRow.getAccountNumberReadOnly()          );
      XxcsoUtils.debug(txn, "ISRSVFLG            �F"
                              + registRow.getIsRsvFlg()                       );
// 2010-03-23 [E_�{�ғ�_01942] Add Start
      XxcsoUtils.debug(txn, "SALEBASECODE        �F"
                              + registRow.getSaleBaseCode()                   );
      XxcsoUtils.debug(txn, "RSVSALEBASECODE     �F"
                              + registRow.getRsvSaleBaseCode()                );
      XxcsoUtils.debug(txn, "RSVSALEBASEACTDATE  �F"
                              + registRow.getRsvSaleBaseActDate()             );
// 2010-03-23 [E_�{�ғ�_01942] Add End
// 2015-09-08 [E_�{�ғ�_13307] Add Start
      XxcsoUtils.debug(txn, "DATATYPE            �F"
                              + registRow.getCustomerClassCode()              );
// 2015-09-08 [E_�{�ғ�_13307] Add End
// 2009-05-07 [T1_0708] Add Start
      byte rowState = registRow.getXxcsoRtnRsrcVEO().getEntityState();
      if ( rowState == OAPlsqlEntityImpl.STATUS_MODIFIED )
      {
// 2009-05-07 [T1_0708] Add End
// 2010-03-23 [E_�{�ғ�_01942] Add Start
//      //��ʍ��ځu�V�S���v���ꋒ�_�����݃`�F�b�N
//      if ( registRow.getNextResource() != null
//        && ! registRow.getNextResource().equals("")
//        && registRow.getAccountNumber() != null
//        && ! registRow.getAccountNumber().equals("") )
//      {
//        if ( ! chkExistEmployee( txn, registRow.getNextResource(), baseCode ) )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00422,
//                XxcsoConstants.TOKEN_INDEX,
//                String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//      }
// 2010-03-23 [E_�{�ғ�_01942] Add End

// 2015-09-08 [E_�{�ғ�_13307] Del Start
//        //��ʍ��ځu�V���[�gNo�v�Ó����`�F�b�N
//        if ( registRow.getNextRouteNo() != null
//          && ! registRow.getNextRouteNo().equals("")
//          && registRow.getAccountNumber() != null
//          && ! registRow.getAccountNumber().equals("") )
//        {
//          if ( ! chkRouteNo( txn , registRow.getNextRouteNo() ) )
//          {
//            OAException error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00514,
//                  XxcsoConstants.TOKEN_INDEX,
//                  String.valueOf(index)
//                );
//            errorList.add(error);
//          }
//        }
// 2015-09-08 [E_�{�ғ�_13307] Del End
      //��ʍ��ځu�V�S���v�u�V���[�gNo�v�ɓ��͒l�����݂���ڋq�R�[�h���擾
      if ( ( registRow.getNextResource() != null
        && ! registRow.getNextResource().equals("") )
        || registRow.getNextRouteNo() != null
        && ! registRow.getNextRouteNo().equals("") )
      {
        //��ʍ��ځu�ڋq�R�[�h�v���ꑶ�݃`�F�b�N
        for ( int i = 0 ; i < coAccountList.size() ; i++ )
        {
          if ( coAccountList.get(i) != null
            && !coAccountList.get(i).equals("")
            && coAccountList.get(i).equals( registRow.getAccountNumber() ) )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00515,
                  XxcsoConstants.TOKEN_INDEX,
                  String.valueOf(index)
                );
            errorList.add(error);
            isSameErr = true;
            continue;
          }
        }
        if ( !isSameErr )
        {
          coAccountList.add(registRow.getAccountNumber());
        }
        isSameErr = false;
      }
// 2010-03-23 [E_�{�ғ�_01942] Add Start
//      //�\�񔄏㋒�_�������_�̏ꍇ
//      if ( ! isRsvAccount
//        && registRow.getAccountNumber() != null
//        && ! registRow.getAccountNumber().equals("")
//        && registRow.getIsRsvFlg() != null
//        && registRow.getIsRsvFlg().equals(
//             XxcsoRtnRsrcBulkUpdateConstants.BOOL_ISRSV)
//        && ( ( registRow.getNextResource() != null
//            && ! registRow.getNextResource().equals("") )
//            || registRow.getNextRouteNo() != null
//            && ! registRow.getNextRouteNo().equals("")) )
//      {
//        isRsvAccount = true;
//      }
// 2010-03-23 [E_�{�ғ�_01942] Add End
// 2009-05-07 [T1_0708] Add Start
      }
// 2009-05-07 [T1_0708] Add End

// 2010-03-23 [E_�{�ғ�_01942] Add Start
      if ( rowState == OAPlsqlEntityImpl.STATUS_MODIFIED ||
           rowState == OAPlsqlEntityImpl.STATUS_NEW )
      {
// 2015-09-08 [E_�{�ғ�_13307] Add Start
        //���|�Ǘ���ڋq�ȊO
        if ( ! XxcsoRtnRsrcBulkUpdateConstants.CUSTOMER_CLASS_14.equals(registRow.getCustomerClassCode()) )
        {
          //��ʍ��ځu�V���[�gNo�v�Ó����`�F�b�N
          if ( registRow.getNextRouteNo() != null
            && ! registRow.getNextRouteNo().equals("")
            && registRow.getAccountNumber() != null
            && ! registRow.getAccountNumber().equals("") )
          {
            if ( ! chkRouteNo( txn , registRow.getNextRouteNo() ) )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00514,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
          }
// 2015-09-08 [E_�{�ғ�_13307] Add End
          //���㋒�_�`�F�b�N
          if (initRow.getReflectMethod() != null && ! "".equals(initRow.getReflectMethod())
             )
          {
            //�u���f���@�v�������f�̏ꍇ
            if (initRow.getReflectMethod().equals(XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT))
            {
              // ���㋒�_�`�F�b�N
              if ( registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("")
                && ( ( registRow.getNextResource() != null
                    && ! registRow.getNextResource().equals("") )
                    || registRow.getNextRouteNo() != null
                    && ! registRow.getNextRouteNo().equals("")) )
              {
                if (!(chkExistBaseCode(txn, baseCode ,registRow.getSaleBaseCode())
                     )
                   )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00603,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              //��ʍ��ځu�V�S���v���ꋒ�_�����݃`�F�b�N
              if ( registRow.getNextResource() != null
                && ! registRow.getNextResource().equals("")
                && registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("") )
              {
                if ( ! chkExistEmployee( txn, registRow.getNextResource(), initRow.getCurrentDate(), baseCode ) )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00422,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
            }
            //�u���f���@�v�\�񔽉f�̏ꍇ
            else
            {
              // ���㋒�_�A�\�񔄏㋒�_�`�F�b�N�̏ꍇ
              if ( registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("")
                && ( ( registRow.getNextResource() != null
                    && ! registRow.getNextResource().equals("") )
                    || registRow.getNextRouteNo() != null
                    && ! registRow.getNextRouteNo().equals("")) )
              {
                if (!(chkExistRcvBaseCode (txn, 
                                           baseCode ,
                                           initRow.getNextDate(),
                                           registRow.getSaleBaseCode(),
                                           registRow.getRsvSaleBaseCode(),
                                           registRow.getRsvSaleBaseActDate()
                                          )
                     )
                   )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00603,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              //��ʍ��ځu�V�S���v���ꋒ�_�����݃`�F�b�N
              if ( registRow.getNextResource() != null
                && ! registRow.getNextResource().equals("")
                && registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("") )
              {
                if ( ! chkExistEmployee( txn, registRow.getNextResource() , initRow.getNextDate() , baseCode ) )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00422,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
            }
          }
// 2015-09-08 [E_�{�ғ�_13307] Add Start
        }
        else
        {
          if (initRow.getReflectMethod() != null && ! "".equals(initRow.getReflectMethod())
             )
          {
            //�\�񔽉f�̏ꍇ�G���[
            if ( initRow.getReflectMethod().equals(XxcsoRtnRsrcBulkUpdateConstants.REFLECT_RSV) )
            {
              OAException error
                      = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00790,
                          XxcsoConstants.TOKEN_INDEX,
                          String.valueOf(index)
                        );
              errorList.add(error);
            }
            //��ʍ��ځu�V���[�gNo�v���ݒ肳��Ă���ꍇ�G���[
            if ( registRow.getNextRouteNo() != null
              && ! registRow.getNextRouteNo().equals("")
              && registRow.getAccountNumber() != null
              && ! registRow.getAccountNumber().equals("") )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00789,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
            //�������_�`�F�b�N
            if ( ! chkExistReceivableBaseCode( txn, registRow.getAccountNumber() , baseCode ) )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00788,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
            //��ʍ��ځu�V�S���v���ꋒ�_�����݃`�F�b�N
            if ( registRow.getNextResource() != null
              && ! registRow.getNextResource().equals("")
              && registRow.getAccountNumber() != null
              && ! registRow.getAccountNumber().equals("") )
            {
              if ( ! chkExistEmployee( txn, registRow.getNextResource() , initRow.getNextDate() , baseCode ) )
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00422,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
          }
        }
// 2015-09-08 [E_�{�ғ�_13307] Add End
      }
// 2010-03-23 [E_�{�ғ�_01942] Add End
      /* 20090402_abe_T1_0125 START*/
      //�ǉ��{�^���Ŗ����͂̏ꍇ�͍s���폜
      if ( ((( registRow.getNextResource() == null)
        || registRow.getNextResource().equals(""))
        && ((registRow.getNextRouteNo() == null)
        || registRow.getNextRouteNo().equals(""))
        && (registRow.getAccountNumberReadOnly().equals(Boolean.FALSE) ))
        /* 20090819_abe_0001123 START*/
        || ((registRow.getAccountNumber() == null)
          || registRow.getAccountNumber().equals(""))
        /* 20090819_abe_0001123 END*/
        )
      {
        registRow.remove();
      }
      /* 20090402_abe_T1_0125 END*/
      //���s�Ɉڍs
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }

    //��ʍ��ځu���f���@�v�I���`�F�b�N
    String reflectMethod = initRow.getReflectMethod();
    XxcsoUtils.debug(txn, "���f���@ = " + reflectMethod);

    if ( reflectMethod == null || "".equals(reflectMethod) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00423,
            XxcsoConstants.TOKEN_COLUMN,
            XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_REFLECTMETHOD
          );
      errorList.add(error);
    }
    
// 2010-03-23 [E_�{�ғ�_01942] Add Start
//    //��ʍ��ځu���f���@�v�������f���\�񔄏㋒�_���݃`�F�b�N
//    if ( isRsvAccount
//      && initRow.getReflectMethod() != null
//      && initRow.getReflectMethod().equals(
//           XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00475
//          );
//      errorList.add(error);
//    }
// 2010-03-23 [E_�{�ғ�_01942] Add End
    
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �S���c�ƈ����_�����݃`�F�b�N
   * @param txn         OADBTransaction�C���X�^���X
   * @param employeeNo  �]�ƈ��ԍ�
   * @param baseCodeDate �Ώۋ��_���t
   * @param baseCode    ���_�R�[�h
   * @return boolean    TRUE:���݂��� FALSE:���݂��Ȃ�
   *****************************************************************************
   */
  private boolean chkExistEmployee(
    OADBTransaction txn
   ,String employeeNo
// 2010-03-23 [E_�{�ғ�_01942] Add Start
   ,Date   baseCodeDate
// 2010-03-23 [E_�{�ғ�_01942] Add End
   ,String baseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateEmployeeVOImpl empVo
      = getXxcsoRtnRsrcBulkUpdateEmployeeVO();
    if ( empVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateEmployeeVO"
        );
    }

    empVo.initQuery(
      employeeNo
// 2010-03-23 [E_�{�ғ�_01942] Add Start
     ,baseCodeDate
// 2010-03-23 [E_�{�ғ�_01942] Add End
     ,baseCode
    );

    //�����̏]�ƈ��ԍ������O�C�����[�U�̓��ꋒ�_���ɑ��݂���ꍇ
    if ( empVo.getRowCount() != 0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }

  /*****************************************************************************
   * ���[�gNo�Ó����`�F�b�N
   * @param txn         OADBTransaction�C���X�^���X
   * @param routeNo     �`�F�b�N�Ώۃ��[�gNo
   * @return boolean    TRUE:�Ó� FALSE:��Ó�
   *****************************************************************************
   */
  private boolean chkRouteNo(
    OADBTransaction txn
   ,String routeNo
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    OracleCallableStatement stmt = null;

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_route_common_pkg.validate_route_no_p(");
      sql.append("     iv_route_number   => :1");
      sql.append("    ,ov_retcode        => :2");
      sql.append("    ,ov_error_reason   => :3");
      sql.append("  );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1,  routeNo);
      stmt.registerOutParameter(2, OracleTypes.VARCHAR);
      stmt.registerOutParameter(3, OracleTypes.VARCHAR);
      
      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String retCode     = stmt.getString(2);
      String errMsg      = stmt.getString(3);

      XxcsoUtils.debug(txn, "retCode = " + retCode);
      XxcsoUtils.debug(txn, "errMsg = " + errMsg);

      if ( "0".equals( retCode ) )
      {
        return true;
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ROUTENO
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    XxcsoUtils.debug(txn, "[END]");
    return false;
  }


// 2010-03-23 [E_�{�ғ�_01942] Add Start
  /*****************************************************************************
   * ���㋒�_�`�F�b�N
   * @param txn           OADBTransaction�C���X�^���X
   * @param baseCode      ���_�R�[�h
   * @param salebaseCode  ���㋒�_�R�[�h
   * @return boolean      TRUE:���� FALSE:�ُ�
   *****************************************************************************
   */
  private boolean chkExistBaseCode(
    OADBTransaction txn
   ,String baseCode
   ,String salebaseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    if (salebaseCode == null )
    {
      return true;
    }

    if (baseCode.equals(salebaseCode) )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
  /*****************************************************************************
   * �\�񔄏㋒�_�`�F�b�N
   * @param txn              OADBTransaction�C���X�^���X
   * @param baseCode         ���_�R�[�h
   * @param nextDate         �����P��
   * @param salebaseCode     ���㋒�_�R�[�h
   * @param rcvsalebaseCode  �\�񔄏㋒�_�R�[�h
   * @param rcvsaleActDate   �\�񔄏㋒�_�J�n��
   * @return boolean         TRUE:���� FALSE:�ُ�
   *****************************************************************************
   */
  private boolean chkExistRcvBaseCode(
    OADBTransaction txn
   ,String baseCode
   ,Date   nextDate
   ,String salebaseCode
   ,String rcvsalebaseCode
   ,Date   rcvsaleActDate
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    // ���㋒�_�R�[�h���Ȃ��ꍇ
    if ((salebaseCode == null || "".equals(salebaseCode)) &&
        (rcvsalebaseCode == null || "".equals(rcvsalebaseCode)) 
       )
    {
      return true;
    }

    // ���㋒�_�R�[�h�̏ꍇ
    if (salebaseCode != null && ! "".equals(salebaseCode))
    {
      if (baseCode.equals(salebaseCode) )
      {
        if (rcvsaleActDate == null || "".equals(rcvsaleActDate))
        {
          return true;
        }
        if ( 0 > nextDate.dateValue().compareTo(rcvsaleActDate.dateValue()) )
        {
          return true;
        }
      }
    }
    // �\�񔄏㋒�_�R�[�h�̏ꍇ
    if (rcvsalebaseCode != null && ! "".equals(rcvsalebaseCode))
    {
      if (baseCode.equals(rcvsalebaseCode) )
      {
        if (rcvsaleActDate != null && ! "".equals(rcvsaleActDate))
        {
          if (0 <= nextDate.dateValue().compareTo(rcvsaleActDate.dateValue()) )
          {
            return true;
          }
        }
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
  
// 2010-03-23 [E_�{�ғ�_01942] Add End

// 2015-09-08 [E_�{�ғ�_13307] Add Start
  /*****************************************************************************
   * �������_�`�F�b�N
   * @param txn         OADBTransaction�C���X�^���X
   * @param AccountNumber    �ڋq�R�[�h
   * @param baseCode         ���_�R�[�h
   * @return boolean         TRUE:���݂��� FALSE:���݂��Ȃ�
   *****************************************************************************
   */
  private boolean chkExistReceivableBaseCode(
    OADBTransaction txn
   ,String AccountNumber
   ,String baseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateReceivableVOImpl recVo
      = getXxcsoRtnRsrcBulkUpdateReceivableVO1();
    if ( recVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateReceivableVO"
        );
    }

    recVo.initQuery(
      AccountNumber
     ,baseCode
    );

    //�����̋��_�ƌڋq�̓������_�������ꍇ
    if ( recVo.getRowCount() != 0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
// 2015-09-08 [E_�{�ғ�_13307] Add End

  /*****************************************************************************
   * �K�p�{�^��������Č�������
   *****************************************************************************
   */
  private void reSearch()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }
    
    //////////////////////////////////////
    // �e�s���擾
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();

    //////////////////////////////////////
    // ��������
    //////////////////////////////////////
    sumVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getRouteNo()
// 2010-03-23 [E_�{�ғ�_01942] Add Start
     ,initRow.getBaseCode1()
     ,initRow.getBaseName()
// 2010-03-23 [E_�{�ғ�_01942] Add End
    );
    
    registVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getRouteNo()
// 2010-03-23 [E_�{�ғ�_01942] Add Start
     //,initRow.getBaseCode()
     ,initRow.getBaseCode1()
// 2010-03-23 [E_�{�ғ�_01942] Add End
    );
    
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    
    if ( registRow != null )
    {
      initRow.setAddCustomerButtonRender(Boolean.TRUE);
      while ( registRow != null )
      {
        registRow.setAccountNumberReadOnly(Boolean.TRUE);

        registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
      }
    }
    else
    {
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
    }

    //////////////////////////////////////
    // �����㌟�؏���
    //////////////////////////////////////
    List list = chkAfterSearch( txn, registVo );

    if ( list.size() > 0 )
    {
      OAException.raiseBundledOAException( list );
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �v���t�@�C���ő�\���s���擾����
   * @param  txn OADBTransaction�C���X�^���X
   * @return �v���t�@�C����VO_MAX_FETCH_SIZE�Ŏw�肳�ꂽ�s��
   *****************************************************************************
   */
  private String getVoMaxFetchSize(OADBTransaction txn)
  {

    String maxSize = txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxSize == null || "".equals(maxSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    return maxSize;
  }

// 2010-03-23 [E_�{�ғ�_01942] Add Start

  /*****************************************************************************
   * �e�C�x���g�����̍Ō�ɍs���鏈���ł��B
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    //////////////////////////////////////
    // �e�s���擾
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();


    if ( initRow != null )
    {
      if ( initRow.getBaseCode1() != null )
      {
        initRow.setBaseCodeFlag("Y");
      }
      else
      {
        initRow.setBaseCodeFlag("N");
      }
    }

    XxcsoUtils.debug(txn, "[END]");
  }

// 2010-03-23 [E_�{�ғ�_01942] Add End

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateInitVO1
   */
  public XxcsoRtnRsrcBulkUpdateInitVOImpl getXxcsoRtnRsrcBulkUpdateInitVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateInitVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateSumVO1
   */
  public XxcsoRtnRsrcBulkUpdateSumVOImpl getXxcsoRtnRsrcBulkUpdateSumVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateSumVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateSumVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.server", "XxcsoRtnRsrcBulkUpdateAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcFullVO1
   */
  public XxcsoRtnRsrcFullVOImpl getXxcsoRtnRsrcFullVO1()
  {
    return (XxcsoRtnRsrcFullVOImpl)findViewObject("XxcsoRtnRsrcFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoReflectMethodListVO
   */
  public XxcsoLookupListVOImpl getXxcsoReflectMethodListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoReflectMethodListVO");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateEmployeeVO
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl getXxcsoRtnRsrcBulkUpdateEmployeeVO()
  {
    return (XxcsoRtnRsrcBulkUpdateEmployeeVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateEmployeeVO");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateReceivableVO1
   */
  public XxcsoRtnRsrcBulkUpdateReceivableVOImpl getXxcsoRtnRsrcBulkUpdateReceivableVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateReceivableVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateReceivableVO1");
  }


}