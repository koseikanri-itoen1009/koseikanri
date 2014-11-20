/*============================================================================
* �t�@�C���� : XxpoProvisionRtnMakeLineCO
* �T�v����   : �x���ԕi�쐬���׃R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-01 1.0  �F�{ �a�Y    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo443001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

import java.io.Serializable;
import java.util.Hashtable;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

/***************************************************************************
 * �x���ԕi�쐬���׉�ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE �F�{ �a�Y
 * @version 1.0
 ***************************************************************************
 */
public class XxpoProvisionRtnMakeLineCO extends XxcmnOAControllerImpl
{
  public static final String RCS_ID="$Header$";
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

    // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �˗�No�擾
      String reqNo = pageContext.getParameter(XxpoConstants.URL_PARAM_REQ_NO);

      // �K�p�{�^���E�폜���͏������s��Ȃ��B
      if (pageContext.getParameter("Apply") == null
        && pageContext.getParameter("deleteYesBtn") == null
        && pageContext.getParameter("deleteNoBtn") == null
      ) 
      {
        // �N���敪�擾
        String exeKbn = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);
        // �o�Ɏ��щ�ʂ���J�ڂ��Ă����ꍇ
        if (!XxcmnUtility.isBlankOrNull(exeKbn)) 
        {
          // �˗�No�ɏo�Ɏ��щ�ʂ̈˗�No���Z�b�g
          reqNo = pageContext.getParameter(XxwshConstants.URL_PARAM_REQ_NO);
          // �N���^�C�v�ɋN���敪���Z�b�g
          exeType = exeKbn;
          // �����ݒ�
          Serializable paramHdr[]= { exeType, reqNo };
          // �������������s
          am.invokeMethod("initializeHdr", paramHdr);
        }
        // �����ݒ�
        Serializable param[] = { exeType };
        // �������������s
        am.invokeMethod("initializeLine", param);
      }
      // �������b�Z�[�W�擾
      String mainMessage = pageContext.getParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
      // �������b�Z�[�W�����݂��A�폜�ȊO�̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(mainMessage)
        && pageContext.getParameter("deleteYesBtn") == null
        && pageContext.getParameter("deleteNoBtn") == null
      ) 
      {
        // �����ݒ�
        Serializable paramHdr[] = { exeType, reqNo };
        // �������������s
        am.invokeMethod("initializeHdr", paramHdr);
        // �����ݒ�
        Serializable paramLine[] = { exeType };
        // �������������s
        am.invokeMethod("initializeLine", paramLine);
        // ���b�Z�[�W�{�b�N�X�\��
        pageContext.putDialogMessage(new OAException(mainMessage, OAException.INFORMATION));
      }

    } else 
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(
             pageContext, XxpoConstants.TXN_XXPO443001J, true)) 
      {
        pageContext.redirectToDialogPage(new OADialogPage(STATE_LOSS_ERROR));        
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
    try{
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �N���^�C�v�擾
      String exeType = pageContext.getParameter("ExeType");

      // �K�p�{�^��������
      if (pageContext.getParameter("Apply") != null) 
      {
        // �V�K�t���O�擾
        String newFlag = pageContext.getParameter("NewFlag");
        // �����ݒ�
        Serializable param[] = { exeType };
        // �K�p�������s
        HashMap retParams = (HashMap)am.invokeMethod("doApply", param);
        String tokenName = (String)retParams.get("tokenName");
        if (!XxcmnUtility.isBlankOrNull(tokenName)) 
        {
          // �˗�No�擾
          String reqNo = (String)retParams.get("reqNo");
          // �p�����[�^�pHashMap����
          HashMap pageParams = new HashMap();
          pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
          pageParams.put(XxpoConstants.URL_PARAM_REQ_NO, reqNo);
          MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS, tokenName) };
          pageParams.put(
            XxpoConstants.URL_PARAM_MAIN_MESSAGE,
            pageContext.getMessage(XxcmnConstants.APPL_XXCMN,
                                   XxcmnConstants.XXCMN05001,
                                   tokens));
          boolean isRetainAM = true;
          // �V�K�t���O���uY�v�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(newFlag)) 
          {
            isRetainAM = false;
          }
          // �x���ԕi�쐬���׉�ʂ֑J��
          pageContext.setForwardURL(
              XxpoConstants.URL_XXPO443001JL,
              null,
              OAWebBeanConstants.KEEP_MENU_CONTEXT,
              null,
              pageParams,
              isRetainAM, // Retain AM
              OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
              OAWebBeanConstants.IGNORE_MESSAGES);    
        }

      // �폜�A�C�R��������
      } else if ("deleteRow".equals(pageContext.getParameter(EVENT_PARAM))) 
      {
        // ���C�����b�Z�[�W����
        OAException mainMessage = new OAException(XxcmnConstants.APPL_XXPO
                                                  ,XxpoConstants.XXPO40029);
        // �p�����[�^�pHashtable����
        Hashtable pageParams = new Hashtable();
        // ���הԍ��擾
        String orderLineNumber = pageContext.getParameter("pOrderLineNumber");
        pageParams.put("pOrderLineNumber", orderLineNumber);
        // �_�C�A���O����
        XxcmnUtility.createDialog(
          OAException.CONFIRMATION, //messageType
          pageContext,  //pageContext
          mainMessage,  //mainMessage
          null, //instMessage
          XxpoConstants.URL_XXPO443001JL, //okButtonUrl
          XxpoConstants.URL_XXPO443001JL, //noButtonUrl
          "Yes",  //okButtonLabel
          "No", //noButtonLabel
          "deleteYesBtn", //okButtonItemName
          "deleteNoBtn",  //noButtonItemName
          pageParams  //formParams
        );

      // �폜Yes�{�^��������
      } else if (pageContext.getParameter("deleteYesBtn") != null) 
      {
        // ���הԍ��擾
        String orderLineNumber = pageContext.getParameter("pOrderLineNumber");
        // �����ݒ�
        Serializable param [] = { exeType, orderLineNumber };
        // �폜����
        am.invokeMethod("doDeleteLine", param);

      // �߂�{�^��������
      } else if (pageContext.getParameter("Back") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
        // �˗�No�擾
        String reqNo = pageContext.getParameter("ReqNo");
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // �N���^�C�v
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO, reqNo );    // �˗�No
        pageParams.put(XxpoConstants.URL_PARAM_PREV_URL, XxpoConstants.URL_XXPO443001JL); // �O���URL
        // �x���ԕi�쐬�w�b�_��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001JH,         // url
          null,                                   // functionName
          OAWebBeanConstants.KEEP_MENU_CONTEXT,   // menuContextAction
          null,                                   // menuName
          pageParams,                             // parameters
          true,                                   // retainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,  // addBreadCrumb
          OAWebBeanConstants.IGNORE_MESSAGES);    // messagingLevel

      // �s�}���{�^��������
      } else if (ADD_ROWS_EVENT.equals(pageContext.getParameter(EVENT_PARAM))) 
      {
        // �����ݒ�
        Serializable param[] = { exeType };
        // �������������s
        am.invokeMethod("addRow", param);

      // ����{�^��������
      } else if (pageContext.getParameter("Cancel") != null) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
        // �V�K�t���O�擾
        String newFlag = pageContext.getParameter("NewFlag");
        // �V�K�t���O���uY�v�̏ꍇ�AretainAM��False�őJ��
        boolean isRetainAM = true;
        if (XxcmnConstants.STRING_Y.equals(newFlag)) 
        {
          isRetainAM = false;
        }
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);  // �N���^�C�v
        // �x���ԕi�쐬�v���ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO443001J,         // url
          null,                                   // functionName
          OAWebBeanConstants.KEEP_MENU_CONTEXT,   // menuContextAction
          null,                                   // menuName
          pageParams,                             // parameters
          isRetainAM,                             // retainAM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,  // addBreadCrumb
          OAWebBeanConstants.IGNORE_MESSAGES);    // messagingLevel

      // �o�Ɏ��уA�C�R��������
      } else if ("shippedIcon".equals(pageContext.getParameter(EVENT_PARAM))) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO443001J);
        // ����ID�擾
        String lineId = pageContext.getParameter("ORDER_LINE_ID");
        // �w�b�_�X�V�����擾
        String xohaUpdateDate = pageContext.getParameter("HDR_UPD_DATE");
        // ���׍X�V�����擾
        String xolaUpdateDate = pageContext.getParameter("LINE_UPD_DATE");
        // �p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_RETURN);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_ID,            lineId);
        pageParams.put(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE, xohaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE,   xolaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,            exeType);
        // �o�׎��у��b�g���͉�ʂ֑J��
        pageContext.setForwardURL(
          XxwshConstants.URL_XXWSH920001J_1,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

      // ���Ɏ��уA�C�R��������
      } else if ("shipToIcon".equals(pageContext.getParameter(EVENT_PARAM))) 
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO440001J);
        // ����ID�擾
        String lineId           = pageContext.getParameter("ORDER_LINE_ID");
        // �w�b�_�X�V�����擾
        String xohaUpdateDate   = pageContext.getParameter("HDR_UPD_DATE");
        // ���׍X�V�����擾
        String xolaUpdateDate   = pageContext.getParameter("LINE_UPD_DATE");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_RETURN);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_ID,            lineId);
        pageParams.put(XxwshConstants.URL_PARAM_HEADER_UPDATE_DATE, xohaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_LINE_UPDATE_DATE,   xolaUpdateDate);
        pageParams.put(XxwshConstants.URL_PARAM_EXE_KBN,            exeType);
        // ���Ɏ��у��b�g���͉�ʂ֑J��
        pageContext.setForwardURL(
          XxwshConstants.URL_XXWSH920001J_2,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    
      }
    } catch (OAException oae)
    {
      // ���b�Z�[�W�̏�����
      pageContext.removeParameter(XxpoConstants.URL_PARAM_MAIN_MESSAGE);
      super.initializeMessages(pageContext, oae);
    }
  }
}
