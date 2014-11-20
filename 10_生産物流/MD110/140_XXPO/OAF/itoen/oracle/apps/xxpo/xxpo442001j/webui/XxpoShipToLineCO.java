/*============================================================================
* �t�@�C���� : XxpoShipToLineCO
* �T�v����   : ���Ɏ��ѓ��́E���׃R���g���[��
* �o�[�W���� : 1.1
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-28 1.0  �V���`��     �V�K�쐬
* 2008-08-19 1.1  ��r���     ST�s�#249�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo442001j.webui;

import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;

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

/***************************************************************************
 * ���Ɏ��ѓ��͖��׉�ʂ̃R���g���[���N���X�ł��B
 * @author  ORACLE �V�� �`��
 * @version 1.1
 ***************************************************************************
 */
public class XxpoShipToLineCO extends XxcmnOAControllerImpl
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

    // �y���ʏ����z�u�߂�v�{�^���`�F�b�N
    if (!pageContext.isBackNavigationFired(false)) 
    {
      super.processRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �N���^�C�v�擾
      String exeType = pageContext.getParameter(XxpoConstants.URL_PARAM_EXE_TYPE);
      // �˗�No�擾
      String reqNo   = pageContext.getParameter(XxpoConstants.URL_PARAM_REQ_NO);
      // �N���敪�擾
      String exeKbn  = pageContext.getParameter(XxwshConstants.URL_PARAM_EXE_KBN);
      if (!XxcmnUtility.isBlankOrNull(exeKbn)) 
      {
        // �˗�No�Ɉ����E���o�Ɏ��щ�ʂ���J�ڂ��Ă����˗�No���Z�b�g
        reqNo = pageContext.getParameter(XxwshConstants.URL_PARAM_REQ_NO);
        // �N���^�C�v�ɋN���敪���Z�b�g
        exeType = exeKbn;
        // �����ݒ�
        Serializable paramHdr[] = { exeType, reqNo };
        // �������������s
        am.invokeMethod("initializeHdr", paramHdr);

      }
      // �����ݒ�
      Serializable param[] = { exeType, reqNo };  
      // �������������s
      am.invokeMethod("initializeLine", param);
      
    } else
    {
      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO442001J, true))
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
    try
    {
      super.processFormRequest(pageContext, webBean);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);
      // �N���^�C�v�擾
      String exeType = pageContext.getParameter("ExeType");

     // �߂�{�^���������ꂽ�ꍇ
     if (pageContext.getParameter("Back") != null) 
     {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
          
        // �˗�No�擾
        String reqNo   = pageContext.getParameter("ReqNo");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);
        // �x���w���쐬�w�b�_��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001JH,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

     // ����{�^���������ꂽ�ꍇ
     } else if (pageContext.getParameter("Cancel") != null) 
     {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // �ύX�Ɋւ���x���N���A�������s
        am.invokeMethod("clearWarnAboutChanges");
          
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
        // �x���w���쐬�w�b�_��ʂ֑J��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO442001J,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);    

       // ���Ɏ��уA�C�R�����I�����ꂽ�ꍇ
      } else if ("shipToIcon".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // �ύX�Ɋւ���x���N���A�������s
        am.invokeMethod("clearWarnAboutChanges");
          
        // ����ID�擾
        String lineId           = pageContext.getParameter("ORDER_LINE_ID");
        // �w�b�_�X�V�����擾
        String xohaUpdateDate   = pageContext.getParameter("HDR_UPD_DATE");
        // ���׍X�V�����擾
        String xolaUpdateDate   = pageContext.getParameter("LINE_UPD_DATE");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_STOC ); //�ďo��ʋ敪�u���Ɏ��щ�ʁv
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

      // �o�׎��уA�C�R�����I�����ꂽ�ꍇ
      } else if ("shippedIcon".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO442001J);
        // �ύX�Ɋւ���x���N���A�������s
        am.invokeMethod("clearWarnAboutChanges");

        // ����ID�擾
        String lineId           = pageContext.getParameter("ORDER_LINE_ID");
        // �w�b�_�X�V�����擾
        String xohaUpdateDate   = pageContext.getParameter("HDR_UPD_DATE");
        // ���׍X�V�����擾
        String xolaUpdateDate   = pageContext.getParameter("LINE_UPD_DATE");
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxwshConstants.URL_PARAM_CALL_PICTURE_KBN,   XxwshConstants.CALL_PIC_KBN_STOC); //�ďo��ʋ敪�u���Ɏ��щ�ʁv
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
          
      // �K�p�{�^���������ꂽ�ꍇ
      } else if (pageContext.getParameter("Apply") != null) 
      {
        // �V�K�t���O�擾
        String newFlag = pageContext.getParameter("NewFlag");
        // �����ݒ�
        Serializable param[] = { exeType };
        // �K�p�������s
        HashMap retParams = (HashMap)am.invokeMethod("doApply", param);
        String  tokenName = (String)retParams.get("tokenName");
        if (!XxcmnUtility.isBlankOrNull(tokenName)) 
        {
          boolean isRetainAM = true;
          // �V�K�t���O���uY�v�̏ꍇ
          if (XxcmnConstants.STRING_Y.equals(newFlag)) 
          {
            //�p�����[�^�pHashMap����
            HashMap pageParams = new HashMap();
            // �˗�No�擾
            String reqNo   = (String)retParams.get("reqNo");
            //�p�����[�^�pHashMap����
            pageParams.put(XxpoConstants.URL_PARAM_EXE_TYPE, exeType);
            pageParams.put(XxpoConstants.URL_PARAM_REQ_NO,   reqNo);
            MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                       tokenName) };
            pageParams.put(XxpoConstants.URL_PARAM_MAIN_MESSAGE, pageContext.getMessage(XxcmnConstants.APPL_XXCMN,
                                                                 XxcmnConstants.XXCMN05001, 
                                                                 tokens));   
                                                                 
          // ����� (���Ɏ��ѓ��͖��׉��)�֑J��
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO442001JL,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            pageParams,
            isRetainAM, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
            OAWebBeanConstants.IGNORE_MESSAGES);    
          }else 
          {
            MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                       tokenName) };
            // �����������b�Z�[�W
            throw new OAException(XxcmnConstants.APPL_XXCMN,
                                  XxcmnConstants.XXCMN05001, 
                                  tokens,
                                  OAException.INFORMATION, 
                                  null);
          }
        }
      }
      
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }
  }
}
