/*============================================================================
* �t�@�C���� : XxpoOrderReceiptDetailsCO
* �T�v����   : ����������͉��:����ڍ׃R���g���[��
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-26 1.0  �g������     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.webui;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Iterator;
import java.io.Serializable;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.fnd.framework.webui.OAWebBeanConstants;
import oracle.apps.fnd.framework.webui.TransactionUnitHelper;
import oracle.apps.fnd.framework.webui.OADialogPage;

import oracle.apps.fnd.framework.OAApplicationModule;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.domain.Number;

import itoen.oracle.apps.xxcmn.util.webui.XxcmnOAControllerImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * ����������͉��:����ڍ׃R���g���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptDetailsCO extends XxcmnOAControllerImpl
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
      
    // AM�̎擾
    OAApplicationModule am = pageContext.getApplicationModule(webBean);

    // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�߂�{�^�����������Ă��Ȃ��ꍇ
    if (!pageContext.isBackNavigationFired(false)) 
    {


      // **************************** //
      // * �T�u�^�u�����N�N���b�N�� *
      // **************************** //
      if ("OrderDetails1Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "OrderDetails2Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "OrderDetails3Link".equals(pageContext.getParameter(EVENT_PARAM))
        || "LotInfoLink".equals(pageContext.getParameter(EVENT_PARAM))
        || "GreenTeaInfoLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
      
        // ��������

      // ********************************* //
      // * �_�C�A���O��ʁuYes�v������   * //
      // ********************************* //       
      } else if (pageContext.getParameter("Yes") != null) 
      {

        boolean updFlag = false;
        
        // �X�V����
        String ret = (String)am.invokeMethod("apply");
        
        // ����I���̏ꍇ
        if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
        {

          // �X�V�������������ꍇ�́A�t���O�𗧂Ă�
          if (XxcmnConstants.STRING_TRUE.equals(ret)) 
          {
            updFlag = true;
          }
          
          // �o�^�E�X�V����
          HashMap retHash = (HashMap)am.invokeMethod("doAllReceipt");

          ret = (String)retHash.get("RetFlag");
          Object requestId = retHash.get("RequestId");
            
          // ����I���̏ꍇ
          if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
          {
            
            // �X�V�������������ꍇ
            if (updFlag || !XxcmnUtility.isBlankOrNull(requestId))
            {
              // �y���ʏ����z�g�����U�N�V�����I��
              TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

              // �R�~�b�g
              am.invokeMethod("doCommit");

              HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");
              HashMap params = new HashMap();
              params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER, retHashMap.get("HeaderNumber"));
              params.put(XxpoConstants.URL_PARAM_START_CONDITION, retHashMap.get("pStartCondition"));

              // �X�V��������MSG��ݒ肵�A����ʑJ��            
              pageContext.putDialogMessage(new OAException(
                                                  XxcmnConstants.APPL_XXPO,
                                                  XxpoConstants.XXPO30041, 
                                                  null, 
                                                  OAException.INFORMATION, 
                                                  null));

              // URL�p�����[�^���폜
              pageContext.removeParameter("Yes");

              // �ĕ\��
              pageContext.forwardImmediatelyToCurrentPage(
                            params,
                            true,
                            OAWebBeanConstants.ADD_BREAD_CRUMB_NO);
                          
            }
          }
        }
        
        // ����I���łȂ��A���́A�X�V���������������ꍇ�̓��[���o�b�N
        if (XxcmnConstants.RETURN_NOT_EXE.equals(ret) || !updFlag)
        {
          // �y���ʏ����z�g�����U�N�V�����I��
          TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

          // ���[���o�b�N
          am.invokeMethod("doRollBack");
        }

      // ********************************* //
      // * �_�C�A���O��ʁuNo�v������    * //
      // ********************************* //
      } else if (pageContext.getParameter("No") != null) 
      {

        // ���[���o�b�N
        am.invokeMethod("doRollBack");
        
      // **************************** //
      // * �����\����               * //
      // **************************** //      
      } else
      {
        // �y���ʏ����z�u���E�U�u�߂�v�{�^���`�F�b�N�@�g�����U�N�V�����쐬
        TransactionUnitHelper.startTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // *************************** //  
        // * �p�����[�^������    * //
        // *************************** //
        String startCondition = XxpoConstants.START_CONDITION_1; // �f�t�H���g:���j���[����N��(1)
        String headerNumber   = "-1";                            // �f�t�H���g: 

        // *************************** //  
        // * URL�p�����[�^�̎擾     * //
        // *************************** //      
        String pStartCondition = pageContext.getParameter(XxpoConstants.URL_PARAM_START_CONDITION);
        String pHeaderNumber   = pageContext.getParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // ������ʂ���N��
        if (!XxcmnUtility.isBlankOrNull(pStartCondition)
          && (XxpoConstants.START_CONDITION_2.equals(pStartCondition)))
        {
          startCondition = pStartCondition;  // URL�p�����[�^��ݒ�
          headerNumber   = pHeaderNumber;    // URL�p�����[�^��ݒ�
        } else 
        {
          if (!XxcmnUtility.isBlankOrNull(pHeaderNumber))
          {
            headerNumber   = pHeaderNumber;    // URL�p�����[�^��ݒ�            
          }
        }

        // �e��p�����[�^��ݒ�
        HashMap hashParams = new HashMap();
        hashParams.put("StartCondition", startCondition);
        hashParams.put("HeaderNumber", headerNumber);

        // �����ݒ�
        Serializable params[] = { hashParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // ����ʃG���[�J�ڂ̏ꍇ�́A���������������{���Ȃ�
        if (!XxcmnUtility.isBlankOrNull(headerNumber))
        {
          // �������������s
          am.invokeMethod("initialize2", params, parameterTypes);
        }
        
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
      // *   �i�ރ{�^��������    * //
      // ************************* //
      if (pageContext.getParameter("Go") != null) 
      {
        // ���������擾
        String headerNumber  = pageContext.getParameter("TxtHeaderNumber");  // ����No
        String requestNumber = pageContext.getParameter("TxtRequestNumber"); // �x��No

        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put("HeaderNumber",  headerNumber);
        searchParams.put("RequestNumber", requestNumber);
        
        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };

        // �������ړ��͕K�{�`�F�b�N
        am.invokeMethod("doRequiredCheck2", params, parameterTypes); 

        // ����
        am.invokeMethod("doSearch2", params, parameterTypes);

      // ************************* //
      // *   �����{�^��������    * //
      // ************************* //
      } else if (pageContext.getParameter("Delete") != null) 
      {

        // URL�p�����[�^(�����ԍ�)���폜
        pageContext.removeParameter(XxpoConstants.URL_PARAM_HEADER_NUMBER);

        // �ĕ\��
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JD,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          null,
          false, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
          OAWebBeanConstants.IGNORE_MESSAGES);


      // ************************* //
      // *   �����N�N���b�N��    * //
      // ************************* //
      } else if ("LineNumberLink".equals(pageContext.getParameter(EVENT_PARAM)))
      {
        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // ��������(�����ԍ�)�擾
        String searchHeaderNumber = pageContext.getParameter("searchHeaderNumber");
        // ��������(�������הԍ�)�擾
        String searchLineNumber = pageContext.getParameter("searchLineNumber");

        // PVO����URL�p�����[�^���擾
        HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");

        String startCondition = (String)retHashMap.get("pStartCondition");
        
        //�p�����[�^�pHashMap����
        HashMap pageParams = new HashMap();
        pageParams.put(XxpoConstants.URL_PARAM_HEADER_NUMBER,        searchHeaderNumber);
        pageParams.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  searchLineNumber);
        pageParams.put(XxpoConstants.URL_PARAM_START_CONDITION,      startCondition);

        // �������:���͉�ʂ�
        pageContext.setForwardURL(
          XxpoConstants.URL_XXPO310001JM,
          null,
          OAWebBeanConstants.KEEP_MENU_CONTEXT,
          null,
          pageParams,
          true, // Retain AM
          OAWebBeanConstants.ADD_BREAD_CRUMB_NO, 
          OAWebBeanConstants.IGNORE_MESSAGES); 

        
      // ********************************* //
      // *      �������ύX��             * //
      // ********************************* //
      } else if ("ProductedDateChanged".equals(pageContext.getParameter(EVENT_PARAM)))
      {

        // �l�擾
        String changedLineNum  = (String)pageContext.getParameter(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);  // LineNumber

        // �����p�����[�^�pHashMap�ݒ�
        HashMap searchParams = new HashMap();
        searchParams.put(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER,  changedLineNum);

        // �����ݒ�
        Serializable params[] = { searchParams };
        // doSearch�̈����^�ݒ�
        Class[] parameterTypes = { HashMap.class };
      
        // �������ύX������
        am.invokeMethod("productedDateChanged", params, parameterTypes);
        

      // ************************** //
      // * ����{�^��������       * //
      // ************************** //
      } else if (pageContext.getParameter("Cancel") != null)
      {
      
        // PVO����URL�p�����[�^���擾
        HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");

        String startCondition = (String)retHashMap.get("pStartCondition");

        // �y���ʏ����z�g�����U�N�V�����I��
        TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

        // ���[���o�b�N
        am.invokeMethod("doRollBack");
            
        // �擾�����N�������� "1"(���j���[����N��)�̏ꍇ
        if (XxpoConstants.START_CONDITION_1.equals(startCondition))
        {

          // �z�[���֑J��
          pageContext.setForwardURL(XxcmnConstants.URL_OAHOMEPAGE,
                                    GUESS_MENU_CONTEXT,
                                    null,
                                    null,
                                    false, // Do not retain AM
                                    ADD_BREAD_CRUMB_NO,
                                    OAWebBeanConstants.IGNORE_MESSAGES); 

        // �擾�����N�������� "2"(��������������)�̏ꍇ          
        } else 
        {
          
          // �������������ʂ֑J��
          pageContext.setForwardURL(
            XxpoConstants.URL_XXPO310001JS,
            null,
            OAWebBeanConstants.KEEP_MENU_CONTEXT,
            null,
            null,
            true, // Retain AM
            OAWebBeanConstants.ADD_BREAD_CRUMB_NO,
            OAWebBeanConstants.IGNORE_MESSAGES);         
        }

      // ***************************** //
      // *   �K�p�{�^��������        * //
      // ***************************** //
      } else if (pageContext.getParameter("Apply") != null)
      {

        // �o�^�E�X�V�O�`�F�b�N����
        am.invokeMethod("dataCheck");

        // �S��`�F�b�N����
        ArrayList lineIdList = (ArrayList)am.invokeMethod("chkAllReceipt");

        // �����\���ɂ����Čx�����������ꍇ�A�m�F�_�C�A���O�𐶐�
        if (lineIdList.size() > 0)
        {

          // �_�C�A���O��ʕ\���p���b�Z�[�W
          StringBuffer pageHeaderText = new StringBuffer();

          // ArrayList��Iterator�֕ϊ�
          Iterator iteLineIdList = lineIdList.iterator();
          
          // �w�������|���x�������ׂ����݂����
          while (iteLineIdList.hasNext())
          {

            // ��������ID���擾
            Number lineId = (Number)iteLineIdList.next();

            // �����ݒ�
            Serializable params[] = { lineId };
            // getToken�̈����^�ݒ�
            Class[] parameterTypes = { Number.class };
            
            // ��������VO�ɕR�t���A�[���於/�i�ږ�/���b�gNO���擾
            HashMap hashTokens = (HashMap)am.invokeMethod("getToken", params, parameterTypes);

            MessageToken[] tokens = new MessageToken[3];
            tokens[0] = new MessageToken(XxcmnConstants.TOKEN_LOCATION, (String)hashTokens.get(XxcmnConstants.TOKEN_LOCATION));
            tokens[1] = new MessageToken(XxcmnConstants.TOKEN_ITEM,     (String)hashTokens.get(XxcmnConstants.TOKEN_ITEM));
            tokens[2] = new MessageToken(XxcmnConstants.TOKEN_LOT,      (String)hashTokens.get(XxcmnConstants.TOKEN_LOT));

            pageHeaderText = pageHeaderText.append(pageContext.getMessage(
                                                      XxcmnConstants.APPL_XXCMN,
                                                      XxcmnConstants.XXCMN10112,
                                                      tokens));

            // ���s�R�[�h��ǉ�
            pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);
            pageHeaderText = pageHeaderText.append(XxcmnConstants.CHANGING_LINE_CODE);

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
            XxpoConstants.URL_XXPO310001JD,
            XxpoConstants.URL_XXPO310001JD,
            "Yes",
            "No",
            "Yes",
            "No",
            null);

        // �����\���ɂ����Čx�������������ꍇ
        } else
        {

          boolean updFlag = false;
        
          // �X�V����
          String ret = (String)am.invokeMethod("apply");
        
          // ����I���̏ꍇ
          if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
          {

            // �X�V�������������ꍇ�́A�t���O�𗧂Ă�
            if (XxcmnConstants.STRING_TRUE.equals(ret)) 
            {
              updFlag = true;
            }
          
            // �o�^�E�X�V����
            HashMap retHash = (HashMap)am.invokeMethod("doAllReceipt");

            ret = (String)retHash.get("RetFlag");
            Object requestId = retHash.get("RequestId");

            // ����I���̏ꍇ
            if (!XxcmnConstants.RETURN_NOT_EXE.equals(ret))
            {
            
              // �X�V�������������ꍇ
              if (updFlag || !XxcmnUtility.isBlankOrNull(requestId))
              {
                // �y���ʏ����z�g�����U�N�V�����I��
                TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

                // �R�~�b�g
                am.invokeMethod("doCommit");

                HashMap retHashMap = (HashMap)am.invokeMethod("getDetailPageParams");
                HashMap params = new HashMap();
                params.put(XxpoConstants.URL_PARAM_HEADER_NUMBER, retHashMap.get("HeaderNumber"));
                params.put(XxpoConstants.URL_PARAM_START_CONDITION, retHashMap.get("pStartCondition"));

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
                          
              }
            }
          }
          
          // ����I���łȂ��A���́A�X�V���������������ꍇ�̓��[���o�b�N
          if (XxcmnConstants.RETURN_NOT_EXE.equals(ret) || !updFlag)
          {
            // �y���ʏ����z�g�����U�N�V�����I��
            TransactionUnitHelper.endTransactionUnit(pageContext, XxpoConstants.TXN_XXPO310001J);

            // ���[���o�b�N
            am.invokeMethod("doRollBack");
          }
        }
      }
      
    // ��O�����������ꍇ  
    } catch(OAException oae)
    {
      super.initializeMessages(pageContext, oae);
    }

  }

}
