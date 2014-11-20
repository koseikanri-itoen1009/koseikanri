/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchAMImpl
* �T�v����   : SP�ꌈ��������ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
/*******************************************************************************
 * SP�ꌈ�����������邽�߂̃A�v���P�[�V�����E���W���[���N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSearchAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSearchAMImpl()
  {
  }



  /*****************************************************************************
   * �A�v���P�[�V�����E���W���[���̏����������ł��B
   * @param searchClass �����敪
   *****************************************************************************
   */
  public void initDetails(
    String searchClass
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    if ( ! initVo.isPreparedForExecution() )
    {
      initVo.initQuery(
        searchClass
      );

      XxcsoSpDecisionSearchInitVORowImpl initRow
        = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
      initRow.setCopyButtonRender(Boolean.FALSE);
      initRow.setDetailButtonRender(Boolean.FALSE);

      if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(searchClass) )
      {
        initRow.setApplyBaseUserRender(Boolean.FALSE);
      }
      else
      {
        initRow.setApplyBaseUserRender(Boolean.TRUE);
      }
    }
    
    XxcsoLookupListVOImpl statusListVo = getXxcsoSpDecisionStatusListVO();
    if ( statusListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionStatusListVO"
        );      
    }

    statusListVo.initQuery(
      "XXCSO1_SP_STATUS_CD"
     ,"lookup_code"
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����{�^���������̏����ł��B
   *****************************************************************************
   */
  public void handleClearButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    XxcsoSpDecisionSearchInitVORowImpl initRow
      = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
    initVo.initQuery(
      initRow.getSearchClass()
    );

    initRow = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    initRow.setEmployeeNumber(null);
    initRow.setFullName(null);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �����{�^���������̏����ł��B
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionSearchInitVOImpl initVo = getXxcsoSpDecisionSearchInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSearchInitVOImpl"
        );
    }

    XxcsoSpDecisionSearchInitVORowImpl initRow
      = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    sumVo.initQuery(
      initRow.getSearchClass()
     ,initRow.getApplyBaseCode()
     ,initRow.getEmployeeNumber()
     ,initRow.getApplyDateStart()
     ,initRow.getApplyDateEnd()
     ,initRow.getStatus()
     ,initRow.getSpDecisionNumber()
     ,initRow.getCustAccountId()
    );

    if ( sumVo.first() == null )
    {
      initRow.setCopyButtonRender(Boolean.FALSE);
      initRow.setDetailButtonRender(Boolean.FALSE);
    }
    else
    {
      if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(
             initRow.getSearchClass()
           )
         )
      {
        initRow.setCopyButtonRender(Boolean.FALSE);
      }
      else
      {
        initRow.setCopyButtonRender(Boolean.TRUE);
      }
      initRow.setDetailButtonRender(Boolean.TRUE);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �R�s�[�̍쐬�{�^���������̏����ł��B
   *****************************************************************************
   */
  public String handleCopyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    XxcsoSpDecisionSummaryVORowImpl sumRow
      = (XxcsoSpDecisionSummaryVORowImpl)sumVo.first();

    Number spDecisionHeaderId = null;
    boolean existFlag = false;
    
    while ( sumRow != null )
    {
      if ( "Y".equals(sumRow.getSelectFlag()) )
      {
        existFlag = true;
        spDecisionHeaderId = sumRow.getSpDecisionHeaderId();
        break;
      }
      sumRow = (XxcsoSpDecisionSummaryVORowImpl)sumVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00304);
    }

    XxcsoUtils.debug(txn, "[END]");
    
    return spDecisionHeaderId.toString();
  }

  /*****************************************************************************
   * �ڍ׃{�^���������̏����ł��B
   *****************************************************************************
   */
  public String handleDetailButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoSpDecisionSummaryVOImpl sumVo = getXxcsoSpDecisionSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSummaryVOImpl"
        );      
    }

    XxcsoSpDecisionSummaryVORowImpl sumRow
      = (XxcsoSpDecisionSummaryVORowImpl)sumVo.first();

    Number spDecisionHeaderId = null;
    boolean existFlag = false;
    
    while ( sumRow != null )
    {
      if ( "Y".equals(sumRow.getSelectFlag()) )
      {
        existFlag = true;
        spDecisionHeaderId = sumRow.getSpDecisionHeaderId();
        break;
      }
      sumRow = (XxcsoSpDecisionSummaryVORowImpl)sumVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00304);
    }

    XxcsoUtils.debug(txn, "[END]");
    
    return spDecisionHeaderId.toString();
  }

  
  /**
   * 
   * Container's getter for XxcsoSpDecisionSearchInitVO1
   */
  public XxcsoSpDecisionSearchInitVOImpl getXxcsoSpDecisionSearchInitVO1()
  {
    return (XxcsoSpDecisionSearchInitVOImpl)findViewObject("XxcsoSpDecisionSearchInitVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoSpDecisionStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSpDecisionStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSummaryVO1
   */
  public XxcsoSpDecisionSummaryVOImpl getXxcsoSpDecisionSummaryVO1()
  {
    return (XxcsoSpDecisionSummaryVOImpl)findViewObject("XxcsoSpDecisionSummaryVO1");
  }
}