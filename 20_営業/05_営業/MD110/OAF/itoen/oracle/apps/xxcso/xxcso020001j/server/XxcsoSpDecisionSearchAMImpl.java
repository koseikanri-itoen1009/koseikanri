/*============================================================================
* �t�@�C���� : XxcsoSpDecisionSearchAMImpl
* �T�v����   : SP�ꌈ��������ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.5
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS����_     �V�K�쐬
* 2009-04-20 1.1  SCS�������l   [ST��QT1_0619]�����{�^���������s���Ή�
* 2009-08-04 1.2  SCS����_     [SCS��Q0000821]���F�p��ʂ̃R�s�[�{�^���\���Ή�
* 2009-09-02 1.3  SCS�������   [SCS��Q0001265]���������̏C���Ή�
* 2011-04-25 1.4  SCS�ː��a�K   [E_�{�ғ�_07224]SP�ꌈ�Q�ƌ����ύX�Ή�
* 2014-03-13 1.5  SCSK�ː��a�K  [E_�{�ғ�_11670]�ŗ��ύX�x�����b�Z�[�W�o�͑Ή��Ή�
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
// 2014-03-13 [E_�{�ғ�_11670] Add Start
import java.sql.SQLException;
import oracle.apps.fnd.framework.OAException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
// 2014-03-13 [E_�{�ғ�_11670] Add End

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

/* 20090902_abe_0001265 START*/
    Boolean btnFlag = initRow.getCopyButtonRender();
/* 20090902_abe_0001265 END*/
// 2011-04-25 [E_�{�ғ�_07224] Add Start
    Boolean btnFlag2 = initRow.getDetailButtonRender();
// 2011-04-25 [E_�{�ғ�_07224] Add End

    initRow = (XxcsoSpDecisionSearchInitVORowImpl)initVo.first();
    initRow.setEmployeeNumber(null);
    initRow.setFullName(null);
// 2009-04-20 [ST��QT1_0302] Add Start
    if ( XxcsoSpDecisionConstants.APPROVE_MODE.equals(
        initRow.getSearchClass())
    )
    {
      initRow.setApplyBaseUserRender(Boolean.FALSE);
/* 20090902_abe_0001265 START*/
//      initRow.setCopyButtonRender(Boolean.FALSE);
/* 20090902_abe_0001265 END*/
    }
    else
    {
      initRow.setApplyBaseUserRender(Boolean.TRUE);
/* 20090902_abe_0001265 START*/
//      initRow.setCopyButtonRender(Boolean.TRUE);
/* 20090902_abe_0001265 END*/
    }
/* 20090902_abe_0001265 START*/
    if ( Boolean.TRUE.equals(btnFlag) )
    {
      initRow.setCopyButtonRender(Boolean.TRUE);
/* 20090902_abe_0001265 END*/
// 2011-04-25 [E_�{�ғ�_07224] Del Start
//      initRow.setDetailButtonRender(Boolean.TRUE);
// 2011-04-25 [E_�{�ғ�_07224] Del End
/* 20090902_abe_0001265 START*/
    }
    else
    {
      initRow.setCopyButtonRender(Boolean.FALSE);
// 2011-04-25 [E_�{�ғ�_07224] Del Start
//      initRow.setDetailButtonRender(Boolean.FALSE);
// 2011-04-25 [E_�{�ғ�_07224] Del End
    }
/* 20090902_abe_0001265 END*/
// 2009-04-20 [ST��QT1_0302] Add End
// 2011-04-25 [E_�{�ғ�_07224] Add Start
    if ( Boolean.TRUE.equals(btnFlag2) )
    {
      initRow.setDetailButtonRender(Boolean.TRUE);
    }
    else
    {
      initRow.setDetailButtonRender(Boolean.FALSE);
    }
// 2011-04-25 [E_�{�ғ�_07224] Add End
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
// 2009-08-04 [��Q0000821] Mod Start
//      initRow.setCopyButtonRender(Boolean.FALSE);
// 2011-04-25 [E_�{�ғ�_07224] Mod Start
//        initRow.setCopyButtonRender(Boolean.TRUE);
        if ( initRow.getInitActPoBaseCode() == null )
        {
          initRow.setCopyButtonRender(Boolean.TRUE);
        }
        else
        {
          //������s���_�̏ꍇ�A�R�s�[�̎g�p�͕s��
          initRow.setCopyButtonRender(Boolean.FALSE);
        }
// 2011-04-25 [E_�{�ғ�_07224] Mod End
// 2009-08-04 [��Q0000821] Mod End
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

// 2014-03-13 [E_�{�ғ�_11670] Add Start
  /*****************************************************************************
   * ���݂̐łƃR�s�[���̐Ń`�F�b�N�ł��B
   *****************************************************************************
   */
  public Boolean compareTaxCodeCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    Boolean returnValue = Boolean.TRUE;

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

    OracleCallableStatement stmt = null;

    //���בI���`�F�b�N
    while ( sumRow != null )
    {
      if ( "Y".equals(sumRow.getSelectFlag()))
      {

        String ChkResult = null;
        stmt = null;

        try
        {
          StringBuffer sql = new StringBuffer(300);
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_util_common_pkg.compare_tax_code(");
          sql.append("        id_orig_data_tax_date => :2");
          sql.append("       );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);   //�ŗ��� 0:�قȂ�@1:����
          stmt.setDATE(2, sumRow.getOrigDataTaxDate());        //�R�s�[��SP�ꌈ�̍ŏI�X�V��

          stmt.execute();

          ChkResult = stmt.getString(1);
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoSpDecisionConstants.TOKEN_VALUE_COMPARE_TAX_CODE
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
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
          }
        }

        //�ŗ����قȂ�ꍇ
        if ( "0".equals(ChkResult)  )
        {
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00661
              );
          returnValue = Boolean.FALSE;
        }
        break;
      }
      sumRow = (XxcsoSpDecisionSummaryVORowImpl)sumVo.next();
    }

    //�擪�s�ɃJ�[�\����߂�
    sumVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * �o�̓��b�Z�[�W
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * ���b�Z�[�W���擾���܂��B
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }
// 2014-03-13 [E_�{�ғ�_11670] Add End
  
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