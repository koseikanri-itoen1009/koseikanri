/*============================================================================
* �t�@�C���� : XxpoInspectLotRegistCO
* �T�v����   : �������b�g:�o�^�R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����        �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  �˒J�c ���    �V�K�쐬
* 2008-05-09 1.1  �F�{ �a�Y      �����ύX�v��#28,41,43�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370002j.webui;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.io.Serializable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.beans.form.OASubmitButtonBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageDateFieldBean;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;

import oracle.jbo.domain.Number;
import java.sql.SQLException;

/***************************************************************************
 * �������b�g:�o�^�R���g���[���N���X�ł��B
 * @author  ORACLE �˒J�c ���
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotRegistCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header: /cvsrepo/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistCO.java,v 1.11 2008/02/22 08:23:38 usr3149 Exp $";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "%packagename%");

  /**
   * Layout and page setup logic for a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processRequest(pageContext, webBean);

    // �߂�{�^���̔���Ɏg�p����B
    if (!pageContext.isBackNavigationFired(false))
    {
      // �g�����U�N�V�����J�n
      TransactionUnitHelper.startTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370002J);

      // �ϐ���`
      String paramLotId = null;
      Number lotId = null;
      HashMap map = new HashMap();
      // �K�p�{�^���擾
      OASubmitButtonBean applyButton =
        (OASubmitButtonBean)webBean.findChildRecursive("Apply");

      // �p�����[�^�̎擾
      paramLotId = pageContext.getParameter("pSearchLotId");
      if (!XxcmnUtility.isBlankOrNull(paramLotId))
      {
        try
        {
          lotId = new Number(paramLotId);
        } catch (SQLException expt)
        {
          // �s���ȃp�����[�^���n���Ă����ꍇ�B
          // �K�p�{�^�����g�p�s�ɂ���
          applyButton.setDisabled(true);
          // ���b�Z�[�W�̏o��
          throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
        }
      } 
      
      // �A�v���P�[�V�������W���[���̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // �����
      OAMessageLovInputBean lovAttribute8 =
        (OAMessageLovInputBean)webBean.findChildRecursive("Attribute8");
      // �i��
      OAMessageLovInputBean lovItemNo =
        (OAMessageLovInputBean)webBean.findChildRecursive("ItemNo");
      // �ܖ�����
      OAMessageDateFieldBean inputAttribute3 =
        (OAMessageDateFieldBean)webBean.findChildRecursive("Attribute3");

      // �����̐ݒ�(�����\������)
      Serializable[] params = { lotId };
      Class[] paramTypes = { Number.class };
      
      try
      {
        // �����\������
        map = (HashMap)am.invokeMethod("initQuery", params, paramTypes);
      } catch (OAException expt)
      {
        // �K�p�{�^�����g�p�s�ɂ���
        applyButton.setDisabled(true);
        // ���b�Z�[�W�̏o��
        throw expt;
      }

      // �������[�U�ōX�V�̏ꍇ�A�����ƕi�ڂ��Œ肷��B
      if (("1".equals((String)map.get("PeopleCode")) &&
            (!XxcmnUtility.isBlankOrNull(lotId))))
      {
        // �����
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // �i��
        lovItemNo.setReadOnly(true);
        lovItemNo.setCSSClass("OraDataText");        
      }

      // �O�����[�U�A���V�K�̏ꍇ�A�������Œ肵�ܖ�������ҏW�s�ɂ���B
      if (("2".equals((String)map.get("PeopleCode")) &&
           (XxcmnUtility.isBlankOrNull(lotId))))
      {
        // �����
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // �ܖ�����
        inputAttribute3.setReadOnly(true);
        inputAttribute3.setCSSClass("OraDataText");

      // �O�����[�U�A���X�V�̏ꍇ�A�����A�i�ځA�ܖ�������ҏW�s�ɂ���B
      } else if (("2".equals((String)map.get("PeopleCode")) &&
                    (!XxcmnUtility.isBlankOrNull(lotId))))
      {
        // �����
        lovAttribute8.setReadOnly(true);
        lovAttribute8.setCSSClass("OraDataText");
        // �i��
        lovItemNo.setReadOnly(true);
        lovItemNo.setCSSClass("OraDataText");        
        // �ܖ�����
        inputAttribute3.setReadOnly(true);
        inputAttribute3.setCSSClass("OraDataText");
        
      }      
// add start 1.1
      // �������b�Z�[�W�擾
      String mainMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
      if (!XxcmnUtility.isBlankOrNull(mainMessage)) 
      {
        // ���b�Z�[�W�{�b�N�X�\��
        pageContext.putDialogMessage(new OAException(mainMessage, OAException.INFORMATION));
      }
// add end 1.1

    }else
    {
      // �g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(
            pageContext, XxpoConstants.TXN_XXPO370002J, true))
      {
        // �߂�{�^���������ꂽ�ꍇ
        OADialogPage dialogPage = new OADialogPage(NAVIGATION_ERROR);
        pageContext.redirectToDialogPage(dialogPage);
      }      
    }
  }

  /**
   * Procedure to handle form submissions for form elements in
   * a region.
   * @param pageContext the current OA page context
   * @param webBean the web bean corresponding to the region
   */
  public void processFormRequest(OAPageContext pageContext, OAWebBean webBean)
  {
    super.processFormRequest(pageContext, webBean);

    // �ϐ���`
    String lotNo = null;
    Number itemId = null;
    Number lotId = null;
    Number reqNo = null;

    // ��O�i�[�p���X�g��`
    List exptArray = new ArrayList();

    // �p�����[�^�̐ݒ�
    HashMap map = new HashMap();

    // �A�v���P�[�V�������W���[���̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
// add start 1.1
    try
    {
// add end 1.1

// del start 1.1
//    // �K�p�{�^���擾(����p)
//    OASubmitButtonBean applyButton =
//        (OASubmitButtonBean)webBean.findChildRecursive("Apply");
// del end 1.1

    // �u�K�p�v�{�^��������
    if (pageContext.getParameter("Apply") != null)
    {
// add start 1.1
      // ���b�Z�[�W�̏�����
      pageContext.removeParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
// add end 1.1
      // �K�{���̓`�F�b�N
      am.invokeMethod("inputCheck");

      // ���݃`�F�b�N
// del start 1.1
//      am.invokeMethod("existCheck");
// del end 1.1
      // ���b�gNo�̎擾
      lotNo = pageContext.getParameter("HiddenLotNo");      
      // �X�V�̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(lotNo))
      {
        try
        {
          List list = (List)am.invokeMethod("doUpdate");
          OAException oae = OAException.getBundledOAException(list);
          pageContext.putDialogMessage(oae);

          String pLotId = (String)pageContext.getParameter("LotId");
          map.put("pSearchLotId", pLotId);

          // �g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);
          pageContext.forwardImmediatelyToCurrentPage(
            map, true, OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        } catch (OAException oae2)
        {

          // �g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);

          // �G���[���b�Z�[�W�̐ݒ�
          pageContext.putDialogMessage(oae2);
        }
        
      // �V�K�̏ꍇ
      } else
      {
// del start 1.1
//        try
//        {
// del end 1.1
          // ���b�g���A�i�������˗����쐬�����Ăяo��
          List result = (List)am.invokeMethod("doInsert");
          map.put("pSearchLotId", result.get(0));

          // ���b�Z�[�W�����X�g�ɒǉ�
          // ���b�g���쐬�������b�Z�[�W
// mod start 1.1
//          MessageToken[] tokens = {
//            new MessageToken("PROCESS",
//                             XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };

//          exptArray.add(new OAException(
//                          XxcmnConstants.APPL_XXCMN,
//                          XxcmnConstants.XXCMN05001,
//                          tokens,
//                          OAException.INFORMATION,
//                          null));
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS, XxpoConstants.TOKEN_NAME_CREATE_LOT_INFO) };
          map.put(
            XxpoConstants.URL_PARAM_MAIN_MESSAGE,
            pageContext.getMessage(XxcmnConstants.APPL_XXCMN,
                                   XxcmnConstants.XXCMN05001,
                                   tokens));
// mod end 1.1

          if (result.size() > 1) 
          {
            // �i�������˗����쐬�������b�Z�[�W
            MessageToken[] tokens2 =
              { new MessageToken("PROCESS",
                                 XxpoConstants.TOKEN_NAME_CREATE_QT_INSPECTION) };

            exptArray.add(new OAException(
                            XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN05001,
                            tokens2,
                            OAException.INFORMATION,
                            null));
          }
          // �g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(
            pageContext, XxpoConstants.TXN_XXPO370002J);

          // �����ʂ֑J��
// mod start 1.1
//          pageContext.putDialogMessage(
//            OAException.getBundledOAException(exptArray));

//          pageContext.forwardImmediately(
//            "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370002j/webui/XxpoInspectLotRegistPG",
//            null,
//            OAWebBeanConstants.KEEP_MENU_CONTEXT,
//            null,
//            map,
//            true, // ratain AM
//            OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO370002J,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            map,
            false, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
            OAWebBeanConstants.IGNORE_MESSAGES);    
// mod end 1.1

// del start 1.1
/*
        } catch (OAException oae)
        {
          map.put("pSearchLotId", null);
          exptArray.add(oae);

          // �G���[���b�Z�[�W�̐ݒ�
          pageContext.putDialogMessage(
            OAException.getBundledOAException(exptArray));
        }
*/
// del end 1.1
      }

    // �u����v�{�^��������
    }else if (pageContext.getParameter("Cancel") != null)
    {
      // �g�����U�N�V�����I��
      TransactionUnitHelper.endTransactionUnit(
        pageContext, XxpoConstants.TXN_XXPO370002J);
// add start 1.1
      // ���b�gNo�̎擾
      lotNo = pageContext.getParameter("HiddenLotNo");      
      boolean isRetainAM = true;
      if (XxcmnUtility.isBlankOrNull(lotNo)) 
      {
        // �V�K�̏ꍇ
        isRetainAM = false;
      }
// add end 1.1
      // ************************* //
      // * �������b�g��񌟍���ʂ� * //
      // ************************* //
      pageContext.setForwardURL(
// mod start 1.1
//        "OA.jsp?page=/itoen/oracle/apps/xxpo/xxpo370001j/webui/XxpoInspectLotSearchPG",
        XxpoConstants.URL_XXPO370001J,
// mod end 1.1
        null,
        OAWebBeanConstants.KEEP_MENU_CONTEXT,
        null,
        null,
// mod start 1.1
//        false, // retain AM
        isRetainAM,
// mod end 1.1
        OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
        OAWebBeanConstants.IGNORE_MESSAGES);

    // ������/�d�������ύX���ꂽ�ꍇ
    } else if ("ProductDateChanged".equals(
                pageContext.getParameter(EVENT_PARAM)))
    {
      // �ܖ��������Z�o
      am.invokeMethod("getBestBeforeDate");

    // =============================== //
    // =    �l���X�g���N�������ꍇ      = //
    // =============================== //
    } else if (pageContext.isLovEvent())
    {
      // �C�x���g����LOV�̎擾
      String lovInputSourceId = pageContext.getLovInputSourceId();
      
      // �i�ڂ̏ꍇ
      if ("ItemNo".equals(lovInputSourceId))
      {
        if (!XxcmnUtility.isBlankOrNull(
              pageContext.getParameter("Attribute1")))
        {
          // �ܖ��������Z�o
          am.invokeMethod("getBestBeforeDate");
        }
      }
    }
// add start 1.1
    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
// add end 1.1

  }
}
