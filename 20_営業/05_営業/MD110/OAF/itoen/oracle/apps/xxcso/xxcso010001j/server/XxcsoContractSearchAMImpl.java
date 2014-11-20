/*============================================================================
* ファイル名 : XxcsoContractSearchAMImpl
* 概要説明   : 契約書検索アプリケーション・モジュールクラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-10-31 1.0  SCS及川領    新規作成
* 2009-05-26 1.1  SCS柳平直人  [ST障害T1_1165]明細チェック障害対応
* 2009-06-10 1.2  SCS柳平直人  [ST障害T1_1317]明細チェック最大件数対応
* 2010-02-09 1.3  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010001j.util.XxcsoContractConstants;
import java.sql.SQLException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
// 2009-05-26 [ST障害T1_1165] Add Start
import oracle.jbo.domain.Number;
// 2009-05-26 [ST障害T1_1165] Add End

/*******************************************************************************
 * 契約書を検索するためのアプリケーション・モジュールクラスです。
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */

public class XxcsoContractSearchAMImpl extends OAApplicationModuleImpl 
{

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractSearchAMImpl()
  {
  }

  /*****************************************************************************
   * アプリケーション・モジュールの初期化処理です。
   *****************************************************************************
   */
  public void initDetails()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    //SP専決書番号選択条件初期化
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }
    // 他画面からの遷移考慮
    if ( ! newVo.isPreparedForExecution() )
    {
      // 初期化処理実行
      newVo.executeQuery();
    }

    // 検索条件初期化
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractQueryTermsVOImpl");
    }
    // 他画面からの遷移考慮
    if ( ! termsVo.isPreparedForExecution() )
    {
      // 初期化処理実行
      termsVo.executeQuery();

      // 明細初期化
      XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
      if ( summaryVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
      }

      // 明細のボタンを非表示に設定
      setButtonAttribute( XxcsoContractConstants.CONSTANT_COM_KBN2 );
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 参照SP専決書番号項目エラーチェック処理です。
   * @return returnValue
   *****************************************************************************
   */
  public Boolean spHeaderCheck()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    Boolean returnValue = Boolean.TRUE;

    // XxcsoContractNewVO1インスタンスの取得
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }

    XxcsoContractNewVORowImpl newRow = (XxcsoContractNewVORowImpl)newVo.first();
    if ( newRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVORowImpl");
    }

    //未入力チェック
    if ( newRow.getSpDecisionNumber() == null )
    {
      mMessage
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00005,
            XxcsoConstants.TOKEN_COLUMN,
            XxcsoContractConstants.MSG_SP_DECISION_NUMBER
          );
      returnValue = Boolean.FALSE;
    }
    else
    {
      // XxcsoContractAuthorityCheckVO1インスタンスの取得
      XxcsoContractAuthorityCheckVOImpl checkVo
        = getXxcsoContractAuthorityCheckVO1();
      if ( checkVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoContractAuthorityCheckVOImpl"
          );
      }
      //権限チェックパッケージCALL
      checkVo.getAuthority(newRow.getSpDecisionHeaderId());

      XxcsoContractAuthorityCheckVORowImpl checkRow
        = (XxcsoContractAuthorityCheckVORowImpl)checkVo.first();

      if ( checkRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoContractAuthorityCheckVORowImpl"
          );
      }
      // 権限エラー
      if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
             checkRow.getAuthority()) )
      {
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00232
             ,XxcsoConstants.TOKEN_REF_OBJECT
             ,XxcsoContractConstants.MSG_SP_DECISION
             ,XxcsoConstants.TOKEN_CRE_OBJECT
             ,XxcsoContractConstants.MSG_CONTRACT
            );
        returnValue = Boolean.FALSE;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * 進むボタンを押下した際の処理です。
   * @return returnValue
   *****************************************************************************
   */
// 2009-06-10 [ST障害T1_1317] Mod Start
//  public void executeSearch()
  public OAException executeSearch()
// 2009-06-10 [ST障害T1_1317] Mod End
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

// 2009-06-10 [ST障害T1_1317] Add Start
  OAException oaMessage = null;
// 2009-06-10 [ST障害T1_1317] Add End

    // 検索条件取得
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoContractQueryTermsVOImpl"
        );
    }

    XxcsoContractQueryTermsVORowImpl termsRow
      = (XxcsoContractQueryTermsVORowImpl)termsVo.first();
    if ( termsRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoContractQueryTermsVORowImpl"
        );
    }

    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoContractSummaryVOImpl"
        );
    }

    //検索条件が全て設定されていない場合はエラー
    if ( (termsRow.getContractNumber() == null )
      && (termsRow.getInstallAccountNumber() == null)
      && (termsRow.getInstallpartyName() == null) )
    {
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00041);
    }
    else
    {
      // 検索実行
      summaryVo.initQuery(
        termsRow.getContractNumber()
       ,termsRow.getInstallAccountNumber()
       ,termsRow.getInstallpartyName()
      );

      // 件数チェック(firstでnullチェック)
      XxcsoContractSummaryVORowImpl summaryRow
        = (XxcsoContractSummaryVORowImpl)summaryVo.first();

      if ( summaryRow != null )
      {
        //検索結果がある場合はボタンを使用可にする
        setButtonAttribute( XxcsoContractConstants.CONSTANT_COM_KBN1 );
// 2009-06-10 [ST障害T1_1317] Add Start
        // 最大表示件数チェック
        int maxFetchSize = getVoMaxFetchSize(getOADBTransaction());
        int searchCnt    = summaryRow.getLineCount().intValue();
        if (searchCnt > maxFetchSize)
        {
          // 検索件数がFND:ビューオブジェクト最大フェッチサイズを
          // 超えている場合
          oaMessage =
            XxcsoMessage.createWarningMessage(
                XxcsoConstants.APP_XXCSO1_00479
               ,XxcsoConstants.TOKEN_MAX_SIZE
               ,String.valueOf(maxFetchSize)
              );
        }
// 2009-06-10 [ST障害T1_1317] Add End
      }
      else
      {
        //それ以外はボタンを使用不可にする
        setButtonAttribute( XxcsoContractConstants.CONSTANT_COM_KBN2 );
      }

    }

    XxcsoUtils.debug(txn, "[END]");
// 2009-06-10 [ST障害T1_1317] Add Start
    return oaMessage;
// 2009-06-10 [ST障害T1_1317] Add End
  }

  /*****************************************************************************
   * 消去ボタンを押下した際の処理です。
   *****************************************************************************
   */
  public void handleClearButton()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // 検索条件初期化
    XxcsoContractQueryTermsVOImpl termsVo = getXxcsoContractQueryTermsVO1();
    if ( termsVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractQueryTermsVOImpl");
    }
    termsVo.executeQuery();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 明細エラーチェック処理です。
   * @param  mode
   * @return returnValue
   *****************************************************************************
   */
  public Boolean selCheck(String mode)
  {
// 2009-05-26 [ST障害T1_1165] Del Start
//    Boolean returnValue = Boolean.TRUE;
//
//    //検索結果から選択されているレコードを判定し、パラメータとして返す
//    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
//    if ( summaryVo == null )
//    {
//      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
//    }
//
//    XxcsoContractSummaryVORowImpl summaryRow
//      = (XxcsoContractSummaryVORowImpl)summaryVo.first();
//
//    if ( summaryRow == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
//    }
//
//    //ループカウント用
//    int i = 0;
//    //権限エラー番号
//    String errorno = null;
//
//    //明細選択チェック
//    while ( summaryRow != null )
//    {
//      if ( "Y".equals(summaryRow.getSelectFlag()) )
//      {
//        //チェックカウント
//        i = ++i;
//
//        // XxcsoContractAuthorityCheckVO1インスタンスの取得
//        XxcsoContractAuthorityCheckVOImpl checkVo
//          = getXxcsoContractAuthorityCheckVO1();
//        if ( checkVo == null )
//        {
//          throw XxcsoMessage.createInstanceLostError
//            ("XxcsoContractAuthorityCheckVOImpl");
//        }
//
//        //権限チェックパッケージCALL
//        checkVo.getAuthority(
//          summaryRow.getSpDecisionHeaderId()
//        );
//
//        XxcsoContractAuthorityCheckVORowImpl checkRow
//          = (XxcsoContractAuthorityCheckVORowImpl)checkVo.first();
//
//        if ( checkRow == null )
//        {
//          throw XxcsoMessage.createInstanceLostError
//            ("XxcsoContractAuthorityCheckVORowImpl");
//        }
//        //エラーとなったSP専決ヘッダIDを退避
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
//               checkRow.getAuthority()) )
//        {
//          errorno = summaryRow.getSpDecisionHeaderNum();
//        }
//
//        // PDF作成時のエラーチェック
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
//        {
//          // フォーマットチェック
//          if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
//                 summaryRow.getContractFormat())
//             )
//          {
//            mMessage
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00448
//                );
//            returnValue = Boolean.FALSE;
//          }
//        }
//        // コピー作成ボタンのマスタ連携チェック
//        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) &&
//             XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
//               summaryRow.getStatuscd()) &&
//             XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
//               summaryRow.getCooperateFlag())
//             )
//        {
//          mMessage
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00397
//              );
//          returnValue = Boolean.FALSE;
//        }
//      }
//      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
//    }
//
//    //mode＝コピー作成:1,詳細:2,PDF作成:3
//    // PDF作成選択で未選択の場合
//    if ( ( i == 0 ) &&
//         ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) ) )
//    {
//      mMessage
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00039,
//            XxcsoConstants.TOKEN_PARAM2,
//            XxcsoContractConstants.MSG_CONTRACT
//          );
//      returnValue = Boolean.FALSE;
//    }
//    // 未選択or複数行選択の場合
//    else if ( ( i == 0 ) || ( i > 1 ) )
//    {
//      // コピー作成
//      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00037,
//              XxcsoConstants.TOKEN_BUTTON,
//              XxcsoContractConstants.MSG_COPY_CREATE
//            );
//        returnValue = Boolean.FALSE;
//      }
//      // 詳細
//      else if ( XxcsoContractConstants.CONSTANT_COM_KBN2.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00037,
//              XxcsoConstants.TOKEN_BUTTON,
//              XxcsoContractConstants.MSG_DETAILS
//            );
//        returnValue = Boolean.FALSE;
//      }
//    }
//
//    //権限エラー
//    if ( ( i == 1 ) && ( errorno != null  ) )
//    {
//      // コピー作成
//      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00232,
//              XxcsoConstants.TOKEN_REF_OBJECT,
//              XxcsoContractConstants.MSG_SP_DECISION,
//              XxcsoConstants.TOKEN_CRE_OBJECT,
//              XxcsoContractConstants.MSG_CONTRACT
//            );
//        returnValue = Boolean.FALSE;
//      }
//      // PDF作成
//      else if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
//      {
//        mMessage
//          = XxcsoMessage.createErrorMessage(
//              XxcsoConstants.APP_XXCSO1_00232,
//              XxcsoConstants.TOKEN_REF_OBJECT,
//              XxcsoContractConstants.MSG_CONTRACT,
//              XxcsoConstants.TOKEN_CRE_OBJECT,
//              XxcsoContractConstants.MSG_PDF_CREATE
//            );
//        returnValue = Boolean.FALSE;
//      }
//    }
//
//    //先頭行にカーソルを戻す
//    summaryVo.first();
//
//    return returnValue;
// 2009-05-26 [ST障害T1_1165] Del End
// 2009-05-26 [ST障害T1_1165] Add Start
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // メソッド内リテラル値
    final String CONTRACT_NUMBER       = "CONTRACT_NUBMER";
    final String CONTRACT_FORMAT       = "CONTRACT_FORMAT";
    final String SP_DECISION_HEADER_ID = "SP_DECISION_HEADER_ID";
    final String SP_DECISION_NUMBER    = "SP_DECISION_NUMBER";
    final String STATUS_CODE           = "STATUS_CODE";
    final String COOPERATE_FLAG        = "COOPERATE_FLAG";

    Boolean returnValue = Boolean.TRUE;

    XxcsoContractSummaryVOImpl sumVo = getXxcsoContractSummaryVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl sumRow
      = (XxcsoContractSummaryVORowImpl) sumVo.first();
    if ( sumRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }

    // 選択行のListを作成
    List selList = new ArrayList();
    while ( sumRow != null )
    {
      if ( "Y".equals( sumRow.getSelectFlag() ) )
      {
        HashMap map = new HashMap(3);
        map.put( CONTRACT_NUMBER,       sumRow.getContractNumber()            );
        map.put( CONTRACT_FORMAT,       sumRow.getContractFormat()            );
        map.put( SP_DECISION_HEADER_ID, sumRow.getSpDecisionHeaderId()        );
        map.put( SP_DECISION_NUMBER,    sumRow.getSpDecisionHeaderNum()       );
        map.put( STATUS_CODE,           sumRow.getStatuscd()                  );
        map.put( COOPERATE_FLAG,        sumRow.getCooperateFlag()             );
        selList.add( map );
      }
      sumRow = (XxcsoContractSummaryVORowImpl) sumVo.next();
    }

    // 先頭行にカーソルを戻す
    sumVo.first();

    ////////////////////
    // 明細選択チェック
    ////////////////////
    int listSize = selList.size();
    // 明細選択が0件
    if ( listSize == 0
      && XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode)
    )
    {
      // PDF作成ボタン
      mMessage
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00039
           ,XxcsoConstants.TOKEN_PARAM2
           ,XxcsoContractConstants.MSG_CONTRACT
          );
      returnValue = Boolean.FALSE;
    }
    // 明細が0件、または複数選択の場合
    else if ( listSize == 0 || listSize > 1 )
    {
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      {
        // コピー作成
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00037
             ,XxcsoConstants.TOKEN_BUTTON
             ,XxcsoContractConstants.MSG_COPY_CREATE
            );
        returnValue = Boolean.FALSE;
      }
      else if ( XxcsoContractConstants.CONSTANT_COM_KBN2.equals(mode) )
      {
        // 詳細
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00037
             ,XxcsoConstants.TOKEN_BUTTON
             ,XxcsoContractConstants.MSG_DETAILS
            );
        returnValue = Boolean.FALSE;
      }
    }

    // 明細選択部分までで一旦エラー処理を終了
    // ※詳細ボタン押下については別途マスタ連携チェックを行うため終了
    if ( ! returnValue.booleanValue()
      ||   XxcsoContractConstants.CONSTANT_COM_KBN2.equals( mode )
    )
    {
      return returnValue;
    }

    ////////////////////
    // マスタ連携チェック、フォーマットチェック
    ////////////////////
    List authErrList = new ArrayList();

    for (int i = 0; i < listSize; i++ )
    {
      HashMap map = (HashMap) selList.get(i);
      String contractNumber     = (String) map.get( CONTRACT_NUMBER           );
      String contractFormat     = (String) map.get( CONTRACT_FORMAT           );
      Number spDecisionHeaderId = (Number) map.get( SP_DECISION_HEADER_ID     );
      String spDecisionNumber   = (String) map.get( SP_DECISION_NUMBER        );
      String statusCode         = (String) map.get( STATUS_CODE               );
      String cooperateFlag      = (String) map.get( COOPERATE_FLAG            );

      ////////////////////
      // 権限チェック
      ////////////////////
      XxcsoContractAuthorityCheckVOImpl checkVo
        = getXxcsoContractAuthorityCheckVO1();
      if ( checkVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoContractAuthorityCheckVOImpl"
          );
      }

      //権限チェックパッケージCALL
      checkVo.getAuthority( spDecisionHeaderId );

      XxcsoContractAuthorityCheckVORowImpl checkRow
        = (XxcsoContractAuthorityCheckVORowImpl) checkVo.first();

      if ( checkRow == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractAuthorityCheckVORowImpl");
      }

      // 権限エラーチェック
      if ( XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
            checkRow.getAuthority() ) )
      {
        //エラーとなった契約書番号を退避(List)
        authErrList.add( contractNumber );
      }

      ////////////////////
      // 契約書フォーマットチェック
      ////////////////////
      if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
      {
        // PDF作成ボタン押下時のみフォーマットチェック
        if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals( contractFormat ) )
        {
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00448
              );
          returnValue = Boolean.FALSE;
        }
      }

// 2010-02-09 [E_本稼動_01538] Mod Start
      //////////////////////
      //// マスタ連携チェック
      //////////////////////
      //if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      //{
      //// コピーボタン押下時のみマスタ連携チェック
      //  if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals( statusCode )
      //    && XxcsoContractConstants.CONSTANT_COM_KBN0.equals( cooperateFlag )
      //  )
      //  {
      //    mMessage
      //      = XxcsoMessage.createErrorMessage(
      //          XxcsoConstants.APP_XXCSO1_00397
      //        );
      //    returnValue = Boolean.FALSE;
      // }
      //}
// 2010-02-09 [E_本稼動_01538] Mod End
    }

    if ( ! returnValue.booleanValue() )
    {
      return returnValue;
    }

    ////////////////////
    // 権限エラーチェック
    ////////////////////
    if ( authErrList.size() > 0 )
    {
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(mode) )
      {
        // コピー作成
        // ※複数選択は権限チェック前の処理にて起こりえない
        //   発生する場合は1件選択時のみ
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00232,
              XxcsoConstants.TOKEN_REF_OBJECT,
              XxcsoContractConstants.MSG_SP_DECISION,
              XxcsoConstants.TOKEN_CRE_OBJECT,
              XxcsoContractConstants.MSG_CONTRACT
            );
        returnValue = Boolean.FALSE;
      }
      else if ( XxcsoContractConstants.CONSTANT_COM_KBN3.equals(mode) )
      {
        String tokenRecord = getContractNumMsg( authErrList );
        // PDF作成
        // ※複数選択時は発生明細の契約書番号をメッセージに付加
        mMessage
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00571
             ,XxcsoConstants.TOKEN_REF_OBJECT
             ,XxcsoContractConstants.MSG_CONTRACT
             ,XxcsoConstants.TOKEN_CRE_OBJECT
             ,XxcsoContractConstants.MSG_PDF_CREATE
             ,XxcsoConstants.TOKEN_RECORD
             ,tokenRecord
            );
        returnValue = Boolean.FALSE;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
// 2009-05-26 [ST障害T1_1165] Add End
  }

  /*****************************************************************************
   * 契約書作成ボタンを押下した際のURLパラメータ取得処理です。
   * @throw  OAException
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamNew()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // 検索条件取得
    XxcsoContractNewVOImpl newVo = getXxcsoContractNewVO1();
    if ( newVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVOImpl");
    }
    
    XxcsoContractNewVORowImpl newRow
      = (XxcsoContractNewVORowImpl)newVo.first();
    if ( newRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractNewVORowImpl");
    }

    HashMap params = new HashMap();
    // SP専決ヘッダID
    params.put(
      XxcsoConstants.TRANSACTION_KEY1,
      newRow.getSpDecisionHeaderId()
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 
  }

  /*****************************************************************************
   * コピー作成ボタンを押下した際のURLパラメータ取得処理です。
   * @throw  OAException
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamCopy()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    //検索結果から選択されているレコードを判定し、パラメータとして返す
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    HashMap params = new HashMap();

    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // XxcsoContractAuthorityCheckVO1インスタンスの取得
        XxcsoContractAuthorityCheckVOImpl checkVo
          = getXxcsoContractAuthorityCheckVO1();
        if ( checkVo == null )
        {
          throw
            XxcsoMessage.createInstanceLostError(
              "XxcsoContractAuthorityCheckVOImpl"
            );
        }
        // 処理区分
        params.put(
          XxcsoConstants.EXECUTE_MODE
         ,XxcsoContractConstants.CONSTANT_COM_KBN2
        );
        // SP専決ヘッダID
        params.put(
          XxcsoConstants.TRANSACTION_KEY1
         ,summaryRow.getSpDecisionHeaderId()
        );
        // 自動販売機設置契約書ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY2
         ,summaryRow.getContractManagementId()
        );
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return params; 
  }

  /*****************************************************************************
   * 詳細ボタンを押下した際のURLパラメータ取得処理です。
   * @return params
   *****************************************************************************
   */
  public HashMap getUrlParamDetails()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    //検索結果から選択されているレコードを判定し、パラメータとして返す
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    HashMap params = new HashMap();

    while ( summaryRow != null )
    {

      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // XxcsoContractAuthorityCheckVO1インスタンスの取得
        XxcsoContractAuthorityCheckVOImpl checkVo
          = getXxcsoContractAuthorityCheckVO1();
        if ( checkVo == null )
        {
          throw
            XxcsoMessage.createInstanceLostError(
              "XxcsoContractAuthorityCheckVOImpl"
            );
        }
        // 処理区分
        params.put(
          XxcsoConstants.EXECUTE_MODE
         ,XxcsoContractConstants.CONSTANT_COM_KBN1
        );
        // SP専決ヘッダID
        params.put(
          XxcsoConstants.TRANSACTION_KEY1
         ,summaryRow.getSpDecisionHeaderId()
        );
        // 自動販売機設置契約書ID
        params.put(
          XxcsoConstants.TRANSACTION_KEY2
         ,summaryRow.getContractManagementId()
        );
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }
    XxcsoUtils.debug(txn, "[END]");

    return params; 
  }

  /*****************************************************************************
   * 契約書印刷ボタン押下時処理
   * @return OAException 正常終了メッセージ
   *****************************************************************************
   */
  public void handlePdfCreateButton()
  {

    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();

    NUMBER requestId = null;
    OracleCallableStatement stmt = null;

    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // 見積書印刷PGをCALL
        requestId = null;
        stmt = null;

        try
        {
          StringBuffer sql = new StringBuffer(300);
          sql.append("BEGIN");
          sql.append("  :1 := fnd_request.submit_request(");
          sql.append("         application       => 'XXCSO'");
          sql.append("        ,program           => 'XXCSO010A04C'");
          sql.append("        ,description       => NULL");
          sql.append("        ,start_time        => NULL");
          sql.append("        ,sub_request       => FALSE");
          sql.append("        ,argument1         => :2");
          sql.append("       );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.NUMBER);
          stmt.setString(2, summaryRow.getContractManagementId().stringValue());

          stmt.execute();

          requestId = stmt.getNUMBER(1);
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
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

        if ( NUMBER.zero().equals(requestId) )
        {
          try
          {
            StringBuffer sql = new StringBuffer(50);
            sql.append("BEGIN fnd_message.retrieve(:1); END;");

            stmt
              = (OracleCallableStatement)
                  txn.createCallableStatement(sql.toString(), 0);

            stmt.registerOutParameter(1, OracleTypes.VARCHAR);

            stmt.execute();

            String errmsg = stmt.getString(1);

            throw
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00310
               ,XxcsoConstants.TOKEN_CONC
               ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
               ,XxcsoConstants.TOKEN_CONCMSG
               ,errmsg
              );
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
            throw
              XxcsoMessage.createSqlErrorMessage(
                e
               ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
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
        }
        // 正常終了メッセージ
        OAException error
          = XxcsoMessage.createConfirmMessage(
              XxcsoConstants.APP_XXCSO1_00001
             ,XxcsoConstants.TOKEN_RECORD
             ,XxcsoContractConstants.TOKEN_VALUE_PDF_OUT
                + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
                + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
                + requestId.stringValue()
                + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,XxcsoConstants.TOKEN_ACTION
             ,XxcsoContractConstants.TOKEN_VALUE_START
            );
        errorList.add(error);

      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    // カーソルを先頭にする
    summaryVo.first();

    commit();

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * マスタ連携チェック処理です。
   * @return returnValue
   *****************************************************************************
   */
  public Boolean cooperateCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    Boolean returnValue = Boolean.TRUE;

    //インスタンス取得
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();
    if ( summaryRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }

// 2010-02-09 [E_本稼動_01538] Mod Start
    OracleCallableStatement stmt;
    String ContractNumber;
// 2010-02-09 [E_本稼動_01538] Mod End
    //明細選択チェック
    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()) )
      {
        // マスタ連携チェック
// 2010-02-09 [E_本稼動_01538] Mod Start
        // ***********************************
        // データ行を取得
        // ***********************************
        // マスタ連携中チェック
        ContractNumber = null;
        stmt = null;

        try
        {
          StringBuffer sql = new StringBuffer(300);
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010001j_pkg.chk_cooperate_wait(");
          sql.append("        iv_contract_number    => :2");
          sql.append("        );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, summaryRow.getContractNumber());

          stmt.execute();

          ContractNumber = stmt.getString(1);
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractConstants.TOKEN_VALUE_COOPERATE_WAIT_INFO_CHK
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

        if (!(ContractNumber == null || "".equals(ContractNumber)))
        {
        //if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals(
        //       summaryRow.getStatuscd())
        //  && XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
        //       summaryRow.getCooperateFlag())
        //   )
        //{
// 2010-02-09 [E_本稼動_01538] Mod End
          // 詳細、PDF作成は確認ダイアログを表示
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00398
              );
          returnValue = Boolean.FALSE;
        }
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    //先頭行にカーソルを戻す
    summaryVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * 確認ダイアログOKボタン押下時処理（PDF）
   * （ダイアログ未出力時も登録処理としてCallされる）
   *****************************************************************************
   */
  public void handleConfirmPdfOkButton()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    XxcsoUtils.debug(txn, "PDF出力処理");
    this.handlePdfCreateButton();

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * コピー作成、詳細、PDF作成ボタンの制御処理です。
   * @param button  制御対象のボタンを表す区分
   *****************************************************************************
   */
  private void setButtonAttribute(String button)
  {
      XxcsoContractRenderVOImpl renderVo = getXxcsoContractRenderVO1();
      if ( renderVo == null )
      {
        throw XxcsoMessage.createInstanceLostError
          ("XxcsoContractRenderVOImpl");
      }

      XxcsoContractRenderVORowImpl renderRow
        = (XxcsoContractRenderVORowImpl)renderVo.first();
      if ( renderRow == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoContractRenderVORowImpl"
          );
      }
      if ( XxcsoContractConstants.CONSTANT_COM_KBN1.equals( button ) )
      {
        renderRow.setContractRender(Boolean.TRUE); // 表示
      }
      else
      {
        renderRow.setContractRender(Boolean.FALSE); // 非表示
      }
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * コミット処理
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

// 2009-05-26 [ST障害T1_1165] Add Start
  /*****************************************************************************
   * エラー対象契約書番号取得
   *****************************************************************************
   */
  private String getContractNumMsg(List list)
  {
    // エラーメッセージ付加メッセージの生成（契約書番号）
    StringBuffer sbNumber = new StringBuffer();
    sbNumber.append( XxcsoContractConstants.MSG_CONTRACT_NUMBER );
    sbNumber.append( XxcsoConstants.TOKEN_VALUE_DELIMITER3 );

    int listSize = list.size();
    for (int i = 0; i < listSize; i++)
    {
      String contractNumber = (String) list.get(i);
      if ( i != 0 )
      {
        sbNumber.append( XxcsoConstants.TOKEN_VALUE_DELIMITER2 );
      }
      sbNumber.append( contractNumber );
    }

    return new String( sbNumber );
  }
// 2009-05-26 [ST障害T1_1165] Add End

// 2009-06-10 [ST障害T1_1317] Add Start
  /*****************************************************************************
   * プロファイル最大表示行数取得処理
   * @param  txn OADBTransactionインスタンス
   * @return プロファイルのVO_MAX_FETCH_SIZEで指定された行数
   *****************************************************************************
   */
  private int getVoMaxFetchSize(OADBTransaction txn)
  {
    String maxSize = txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);

    if ( maxSize == null || "".equals(maxSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    return Integer.parseInt(maxSize);
  }
// 2009-06-10 [ST障害T1_1317] Add End
// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * 取消済契約書チェックです。
   * @return returnValue
   *****************************************************************************
   */
  public Boolean cancelContractCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    Boolean returnValue = Boolean.TRUE;

    //インスタンス取得
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();
    if ( summaryRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }

    OracleCallableStatement stmt = null;

    //明細選択チェック
    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()))
      {
        // 取消済契約書チェック
        String CancelContractNumber = null;
        stmt = null;

        try
        {
          StringBuffer sql = new StringBuffer(300);
          sql.append("BEGIN");
          sql.append("  :1 := xxcso_010001j_pkg.chk_cancel_contract(");
          sql.append("        iv_contract_number   => :2");
          sql.append("       ,iv_account_number    => :3");
          sql.append("       );");
          sql.append("END;");

          stmt
            = (OracleCallableStatement)
                txn.createCallableStatement(sql.toString(), 0);

          stmt.registerOutParameter(1, OracleTypes.VARCHAR);
          stmt.setString(2, summaryRow.getContractNumber());
          stmt.setString(3, summaryRow.getInstallAccountNumber());

          stmt.execute();

          CancelContractNumber = stmt.getString(1);
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
          throw
            XxcsoMessage.createSqlErrorMessage(
              e
             ,XxcsoContractConstants.TOKEN_VALUE_CANCEL_CONTRACT
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

        if (!(CancelContractNumber == null || "".equals(CancelContractNumber)))
        {
          mMessage
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00594
              );
          returnValue = Boolean.FALSE;
        }
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    //先頭行にカーソルを戻す
    summaryVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }
  /*****************************************************************************
   * 最新契約書チェックです。
   * @return returnValue
   *****************************************************************************
   */
  public Boolean latestContractCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    Boolean returnValue = Boolean.TRUE;

    //インスタンス取得
    XxcsoContractSummaryVOImpl summaryVo = getXxcsoContractSummaryVO1();
    if ( summaryVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVOImpl");
    }

    XxcsoContractSummaryVORowImpl summaryRow
      = (XxcsoContractSummaryVORowImpl)summaryVo.first();
    if ( summaryRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoContractSummaryVORowImpl");
    }
    XxcsoContractAuthorityCheckVOImpl checkVo
      = getXxcsoContractAuthorityCheckVO1();
    if ( checkVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoContractAuthorityCheckVOImpl"
        );
    }



    OracleCallableStatement stmt = null;

    //明細選択チェック
    while ( summaryRow != null )
    {
      if ( "Y".equals(summaryRow.getSelectFlag()))
      {
        // 最新契約書チェック
        String ContractNumber = null;
        stmt = null;

        //権限チェックパッケージCALL
        checkVo.getAuthority( summaryRow.getSpDecisionHeaderId());

        XxcsoContractAuthorityCheckVORowImpl checkRow
          = (XxcsoContractAuthorityCheckVORowImpl) checkVo.first();

        if ( checkRow == null )
        {
          throw XxcsoMessage.createInstanceLostError
            ("XxcsoContractAuthorityCheckVORowImpl");
        }

        // 権限エラーチェック
        if (! XxcsoContractConstants.CONSTANT_COM_KBN0.equals(
              checkRow.getAuthority() ) )
        {
          try
          {
            StringBuffer sql = new StringBuffer(300);
            sql.append("BEGIN");
            sql.append("  :1 := xxcso_010001j_pkg.chk_latest_contract(");
            sql.append("        iv_contract_number   => :2");
            sql.append("       ,iv_account_number    => :3");
            sql.append("       );");
            sql.append("END;");

            stmt
              = (OracleCallableStatement)
                  txn.createCallableStatement(sql.toString(), 0);

            stmt.registerOutParameter(1, OracleTypes.VARCHAR);
            stmt.setString(2, summaryRow.getContractNumber());
            stmt.setString(3, summaryRow.getInstallAccountNumber());

            stmt.execute();

            ContractNumber = stmt.getString(1);
          }
          catch ( SQLException e )
          {
            XxcsoUtils.unexpected(txn, e);
            throw
              XxcsoMessage.createSqlErrorMessage(
                e
               ,XxcsoContractConstants.TOKEN_VALUE_LATEST_CONTRACT
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

          if (!(ContractNumber == null || "".equals(ContractNumber)))
          {
            mMessage
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00593
                 ,XxcsoConstants.TOKEN_RECORD
                 ,ContractNumber
                );
            returnValue = Boolean.FALSE;
          }
          break;
        }
      }
      summaryRow = (XxcsoContractSummaryVORowImpl)summaryVo.next();
    }

    //先頭行にカーソルを戻す
    summaryVo.first();

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }
// 2010-02-09 [E_本稼動_01538] Mod End

  /**
   * 
   * Container's getter for XxcsoContractQueryTermsVO1
   */
  public XxcsoContractQueryTermsVOImpl getXxcsoContractQueryTermsVO1()
  {
    return (XxcsoContractQueryTermsVOImpl)findViewObject("XxcsoContractQueryTermsVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractSummaryVO1
   */
  public XxcsoContractSummaryVOImpl getXxcsoContractSummaryVO1()
  {
    return (XxcsoContractSummaryVOImpl)findViewObject("XxcsoContractSummaryVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso010001j.server", "XxcsoContractSearchAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoContractNewVO1
   */
  public XxcsoContractNewVOImpl getXxcsoContractNewVO1()
  {
    return (XxcsoContractNewVOImpl)findViewObject("XxcsoContractNewVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractAuthorityCheckVO1
   */
  public XxcsoContractAuthorityCheckVOImpl getXxcsoContractAuthorityCheckVO1()
  {
    return (XxcsoContractAuthorityCheckVOImpl)findViewObject("XxcsoContractAuthorityCheckVO1");
  }

  /**
   * 
   * Container's getter for XxcsoContractRenderVO1
   */
  public XxcsoContractRenderVOImpl getXxcsoContractRenderVO1()
  {
    return (XxcsoContractRenderVOImpl)findViewObject("XxcsoContractRenderVO1");
  }


}