/*============================================================================
* �t�@�C���� : XxpoOrderReceiptMakeCO
* �T�v����   : ������э쐬:����������̓R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-04 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.webui;

import com.sun.java.util.collections.HashMap;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;
import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;

import itoen.oracle.apps.xxpo.util.XxpoConstants;
import oracle.apps.fnd.common.MessageToken;

/***************************************************************************
 * ������э쐬:����������̓R���g���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptMakeCO extends XxcmnOAControllerImpl
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

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {
      // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
      TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

      // AM�̎擾
      OAApplicationModule am = pageContext.getApplicationModule(webBean);

      // ********************************* //
      // * �_�C�A���O��ʁuYes�v������   * //
      // ********************************* //       
      if (pageContext.getParameter("Yes") != null) 
      {

          // URL�p�����[�^���폜
          pageContext.removeParameter("Yes");

          // �o�^�E�X�V����
          HashMap retHash = (HashMap)am.invokeMethod("apply2");

          String ret = (String)retHash.get("RetFlag");
          Object requestId = retHash.get("RequestId");

          // ����I���̏ꍇ
          if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);
            
            // �R�~�b�g
            am.invokeMethod("doCommit");

            // ********************************** //
            // *     URL�p�����[�^�ݒ�          * //
            // ********************************** //
            // URL�p�����[�^(�N������)
            // (1:���j���[����N��, 2:������ʂ���J��)
            String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

            // URL�p�����[�^(�����ԍ�)
            String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

            // URL�p�����[�^(�������הԍ����擾)
            String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

            // �����p�����[�^�pHashMap�ݒ�
            HashMap params = new HashMap();
          
            params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
            params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
            params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);  

            // �����ݒ�
            Serializable searchParams[] = { params };
            // doSearch�̈����^�ݒ�
            Class[] parameterTypes = { HashMap.class };
      
            // �I������
            am.invokeMethod("doEndOfProcess", searchParams, parameterTypes);

            // �X�V��������MSG��ݒ肵�A����ʑJ��
            pageContext.putDialogMessage(new OAException(
                                               XxcmnConstants.APPL_XXPO,
                                               XxpoConstants.XXPO30041,
                                               null, 
                                               OAException.INFORMATION,
                                               null));

            pageContext.forwardImmediatelyToCurrentPage(
                          params,
                          true,
                          OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

          // ����I���łȂ��ꍇ�A���[���o�b�N
          } else
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

            // ���[���o�b�N
            am.invokeMethod("doRollBack");

            // ********************************** //
            // *     URL�p�����[�^�ݒ�          * //
            // ********************************** //
            // URL�p�����[�^(�N������)
            // (1:���j���[����N��, 2:������ʂ���J��)
            String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

            // URL�p�����[�^(�����ԍ�)
            String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

            // URL�p�����[�^(�������הԍ����擾)
            String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

            // �����p�����[�^�pHashMap�ݒ�
            HashMap params = new HashMap();
          
            params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
            params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
            params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
            pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                           null,
                                           OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                           null,
                                           params,
                                           true, // retain AM
                                           OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

          }


      // ********************************* //
      // * �_�C�A���O��ʁuNo�v������    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {

        // �����͍s��Ȃ��B��ʂ��ĕ\��

      // ********************************* //
      // *      �O��ʂ���̑J�ڎ�       * //
      // ********************************* //
      } else
      {

        // ********************************** //
        // *     URL�p�����[�^�擾          * //
        // ********************************** //
        // URL�p�����[�^(�N������)
        // (1:���j���[����N��, 2:������ʂ���J��)
        String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);
      
        // URL�p�����[�^(�����ԍ�)
        String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // URL�p�����[�^(�������הԍ����擾)
        String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);
    
        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put("startCondition",  startCondition);
        searchParams.put("headerNumber",    headerNumber);
        searchParams.put("lineNumber",      lineNumber);

        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
      
        // �������������s
        am.invokeMethod("initialize3", params, parameterTypes);      
 
      }

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�������������ꍇ
    } else
    {

      // �y���ʏ����z�g�����U�N�V�����`�F�b�N
      if (!TransactionUnitHelper.isTransactionUnitInProgress(pageContext, XxpoConstants.TXN_XXPO310001J, true))
      { 
        // �y���ʏ����z�G���[�_�C�A���O��ʂ֑J��
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
    super.processFormRequest(pageContext, webBean);

    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);
    
    try
    {
      // ************************* //
      // *   �폜�{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Cancel") != null) 
      {
        // URL�p�����[�^(�N������)
        // (1:���j���[����N��, 2:������ʂ���J��)
        String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_START_CONDITION, startCondition);

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JD,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES);        
      
      // ***************************** //
      // *   �s�}��������            * //
      // ***************************** //
      } else if (pageContext.getParameter("AddRow") != null)
      {
        am.invokeMethod("addRow");

      // ***************************** //
      // *   �K�p�{�^��������        * //
      // ***************************** //
      } else if (pageContext.getParameter("Apply") != null)
      {
        // �K�{���ړ��̓`�F�b�N����ׁ̈A��s�̍폜�����{
        String rowCount = (String)am.invokeMethod("deleteRow");

        // ������א���0�s�ƂȂ��Ă���ꍇ�́A�K�p�����͍s��Ȃ��B
        if (!rowCount.equals(XxcmnConstants.STRING_ZERO)) 
        {

          // �o�^�E�X�V�O�`�F�b�N����
          HashMap messageCode = (HashMap)am.invokeMethod("dataCheck2");

          // �����\���ɂ����Čx�����������ꍇ�A�m�F�_�C�A���O�𐶐�
          if (messageCode.size() > 0)
          {
            // �_�C�A���O��ʕ\���p���b�Z�[�W
            StringBuffer pageHeaderText = new StringBuffer();
          
            // �w�������|���x�܂��́A�w��������v��x�̃��b�Z�[�W���i�[����Ă���ꍇ
            if (messageCode.get(XxcmnConstants.XXCMN10112) != null) 
            {
              // ��������VO�ɕR�t���A�[���於/�i�ږ�/���b�gNO���擾
              Serializable params[] = { XxcmnConstants.STRING_ZERO };
              HashMap hashTokens = (HashMap)am.invokeMethod("getToken2", params);

              MessageToken[] tokens = new MessageToken[3];
              tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
              tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
              tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));


              pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                       XxcmnConstants.APPL_XXCMN, 
                                                       XxcmnConstants.XXCMN10112,
                                                       tokens));
            }
            
            // �w��������x�̃��b�Z�[�W���i�[����Ă���ꍇ
            if (messageCode.get(XxcmnConstants.XXCMN10110) != null) 
            {
              // ��������VO�ɕR�t���A�����݌ɓ��ɐ於/�i�ږ�/���b�gNO���擾
              Serializable params[] = { XxcmnConstants.STRING_ONE };
              HashMap hashTokens = (HashMap)am.invokeMethod("getToken2", params);

              MessageToken[] tokens = new MessageToken[3];
              tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
              tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
              tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));

              // ���b�Z�[�W���������݂���ꍇ
              if (pageHeaderText.length() > 0)
              {
                // ���s�R�[�h��ǉ�
                pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
                pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
              }
              
              pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                       XxcmnConstants.APPL_XXCMN, 
                                                       XxcmnConstants.XXCMN10110,
                                                       tokens));              
            }

            // ���C�����b�Z�[�W�쐬 
            MessageToken[] mainTokens = new MessageToken[1];
            mainTokens[0] = new MessageToken(XxcmnConstants.TOKEN_TOKEN, pageHeaderText.toString());

            OAException mainMessage = new OAException(
                                            XxcmnConstants.APPL_XXCMN,
                                            XxcmnConstants.XXCMN00025,
                                            mainTokens);
                                                      
            // �_�C�A���O���b�Z�[�W��\��
            XxcmnUtility.createDialog(
              OAException.CONFIRMATION,
              pageContext,
              mainMessage,
              null,
              XxpoConstants.URL_XXPO310001JM,
              XxpoConstants.URL_XXPO310001JM,
              "Yes",
              "No",
              "Yes",
              "No",
              null);
              
          // �����\���ɂ����Čx�������������ꍇ              
          } else
          {

            // �o�^�E�X�V����
            HashMap retHash = (HashMap)am.invokeMethod("apply2");

            String ret = (String)retHash.get("RetFlag");
            Object requestId = retHash.get("RequestId");

            // ����I���̏ꍇ
            if (XxcmnConstants.RETURN_SUCCESS.equals(ret))
            {

              // �y���ʏ����z�g�����U�N�V�����I��
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);
            
              // �R�~�b�g
              am.invokeMethod("doCommit");

              // ********************************** //
              // *     URL�p�����[�^�ݒ�          * //
              // ********************************** //
              // URL�p�����[�^(�N������)
              // URL�p�����[�^(�����ԍ�)
              String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

              // URL�p�����[�^(�������הԍ����擾)
              String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

              // �����p�����[�^�pHashMap�ݒ�
              HashMap params = new HashMap();
          
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,        headerNumber);
              params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  lineNumber);  

              // �����ݒ�
              Serializable searchParams[] = { params };
              // doSearch�̈����^�ݒ�
              Class[] parameterTypes = { HashMap.class };
      
              // �I������
              am.invokeMethod("doEndOfProcess", searchParams, parameterTypes);

              // �X�V��������MSG��ݒ肵�A����ʑJ��
              pageContext.putDialogMessage(new OAException(
                                                 XxcmnConstants.APPL_XXPO,
                                                 XxpoConstants.XXPO30041, 
                                                 null, 
                                                 OAException.INFORMATION, 
                                                 null));

              pageContext.forwardImmediatelyToCurrentPage(
                            params,
                            true,
                            OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

            // ����I���łȂ��ꍇ�A���[���o�b�N
            } else
            {

              // �y���ʏ����z�g�����U�N�V�����I��
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

              // ���[���o�b�N
              am.invokeMethod("doRollBack");

              // ********************************** //
              // *     URL�p�����[�^�ݒ�          * //
              // ********************************** //
              // URL�p�����[�^(�N������)
              // (1:���j���[����N��, 2:������ʂ���J��)
              String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

              // URL�p�����[�^(�����ԍ�)
              String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

              // URL�p�����[�^(�������הԍ����擾)
              String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

              // �����p�����[�^�pHashMap�ݒ�
              HashMap params = new HashMap();
          
              params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
              params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
              pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                             null,
                                             OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                             null,
                                             params,
                                             true, // retain AM
                                             OAWebBeanConstants.ADD_BREAD_CRUMB_NO);

            }
          }
        // ������א���0�s�ƂȂ��Ă���ꍇ�́A����ʑJ��
        } else
        {

          // ********************************** //
          // *     URL�p�����[�^�ݒ�          * //
          // ********************************** //
          // URL�p�����[�^(�N������)
          // (1:���j���[����N��, 2:������ʂ���J��)
          String startCondition = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);

          // URL�p�����[�^(�����ԍ�)
          String headerNumber   = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

          // URL�p�����[�^(�������הԍ����擾)
          String lineNumber     = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

          // �����p�����[�^�pHashMap�ݒ�
          HashMap params = new HashMap();
          
          params.put(XxpoConstants.URL_PARAM_START_CONDITION,  startCondition);
          params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,    headerNumber);
          params.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,      lineNumber);         
        
          pageContext.forwardImmediately(XxpoConstants.URL_XXPO310001JM,
                                         null,
                                         OAWebBeanConstants.KEEP_MENU_CONTEXT,
                                         null,
                                         params,
                                         true, // retain AM
                                         OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
        }
      }
      
    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
