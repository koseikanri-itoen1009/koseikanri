/*============================================================================
* ファイル名 : XxcsoSpDecisionReflectUtils
* 概要説明   : SP専決反映ユーティリティクラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
* 2009-03-23 1.1  SCS柳平直人   [ST障害T1_0163]課題No.115取り込み
* 2009-05-19 1.2  SCS柳平直人   [ST障害T1_1058]reflectAll時契約先反映処理追加
* 2009-05-28 1.3  SCS柳平直人   [ST障害T1_1216]設置先反映処理不具合対応
* 2009-10-14 1.4  SCS阿部大輔   [共通課題IE554,IE573]住所対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.Number;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCcLineInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCcLineInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBmFormatVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBmFormatVORowImpl;
import java.sql.CallableStatement;
import java.sql.Types;
import java.sql.SQLException;

/*******************************************************************************
 * SP専決書の各種値の反映を行うためのユーティリティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionReflectUtils 
{
  /*****************************************************************************
   * 契約先反映
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param cntrctVo     契約先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectContract(
    XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();

    String sameInstAcctFlag = cntrctRow.getSameInstallAccountFlag();

    if ( "Y".equals(sameInstAcctFlag) )
    {
      if ( isDiffer(cntrctRow.getCustomerId(), null) )
      {
        cntrctRow.setCustomerId(null);
      }
      if ( isDiffer(cntrctRow.getContractNumber(), null) )
      {
        cntrctRow.setContractNumber(null);
      }
      if ( isDiffer(cntrctRow.getPartyName(), installRow.getPartyName()) )
      {
        cntrctRow.setPartyName(
          installRow.getPartyName()
        );
      }
      if ( isDiffer(cntrctRow.getPartyNameAlt(), installRow.getPartyNameAlt()) )
      {
        cntrctRow.setPartyNameAlt(
          installRow.getPartyNameAlt()
        );
      }
      if ( isDiffer(
             cntrctRow.getPostalCodeFirst()
            ,installRow.getPostalCodeFirst()
           )
         )
      {
        cntrctRow.setPostalCodeFirst(
          installRow.getPostalCodeFirst()
        );
      }
      if ( isDiffer(
             cntrctRow.getPostalCodeSecond()
            ,installRow.getPostalCodeSecond()
           )
         )
      {
        cntrctRow.setPostalCodeSecond(
          installRow.getPostalCodeSecond()
        );
      }
      if ( isDiffer(cntrctRow.getState(), installRow.getState()) )
      {
        cntrctRow.setState(
          installRow.getState()
        );
      }
      if ( isDiffer(cntrctRow.getCity(), installRow.getCity()) )
      {
        cntrctRow.setCity(
          installRow.getCity()
        );
      }
      if ( isDiffer(cntrctRow.getAddress1(), installRow.getAddress1()) )
      {
        cntrctRow.setAddress1(
          installRow.getAddress1()
        );
      }
      if ( isDiffer(cntrctRow.getAddress2(), installRow.getAddress2()) )
      {
        cntrctRow.setAddress2(
          installRow.getAddress2()
        );
      }
      if ( isDiffer(
             cntrctRow.getAddressLinesPhonetic()
            ,installRow.getAddressLinesPhonetic()
           )
         )
      {
        cntrctRow.setAddressLinesPhonetic(
          installRow.getAddressLinesPhonetic()
        );
      }
    }
    else
    {
      if ( isDiffer(cntrctRow.getCustomerId(), null) )
      {
        cntrctRow.setCustomerId(null);
      }
      if ( isDiffer(cntrctRow.getContractNumber(), null) )
      {
        cntrctRow.setContractNumber(null);
      }
      if ( isDiffer(cntrctRow.getPartyName(), null) )
      {
        cntrctRow.setPartyName(null);
      }
      if ( isDiffer(cntrctRow.getPartyNameAlt(), null) )
      {
        cntrctRow.setPartyNameAlt(null);
      }
      if ( isDiffer(cntrctRow.getPostalCodeFirst(), null) )
      {
        cntrctRow.setPostalCodeFirst(null);
      }
      if ( isDiffer(cntrctRow.getPostalCodeSecond(), null) )
      {
        cntrctRow.setPostalCodeSecond(null);
      }
      if ( isDiffer(cntrctRow.getState(), null) )
      {
        cntrctRow.setState(null);
      }
      if ( isDiffer(cntrctRow.getCity(), null) )
      {
        cntrctRow.setCity(null);
      }
      if ( isDiffer(cntrctRow.getAddress1(), null) )
      {
        cntrctRow.setAddress1(null);
      }
      if ( isDiffer(cntrctRow.getAddress2(), null) )
      {
        cntrctRow.setAddress2(null);
      }
      if ( isDiffer(cntrctRow.getAddressLinesPhonetic(), null) )
      {
        cntrctRow.setAddressLinesPhonetic(null);
      }
    }
  }


  /*****************************************************************************
   * 取引条件反映
   * @param headerVo         SP専決ヘッダ登録／更新用ビューインスタンス
   * @param scVo             売価別条件登録／更新用ビューインスタンス
   * @param allCcVo          全容器一律登録／更新用ビューインスタンス
   * @param selCcVo          容器別条件登録／更新用ビューインスタンス
   * @param ccLineInitVo     一律条件・容器別条件初期化用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectConditionBusiness(
    XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionCcLineInitVOImpl      ccLineInitVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    
    ///////////////////////////////////////////
    // 本処理
    ///////////////////////////////////////////    
    String condBizType      = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();

    if ( condBizType == null || "".equals(condBizType) )
    {
      if ( isDiffer(headerRow.getAllContainerType(), null) )
      {
        headerRow.setAllContainerType(null);
      }
    }
    else
    {
      // 売価別条件
      // 売価別条件（寄付金登録用）
      if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
           XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
         )
      {
        if ( isDiffer(headerRow.getAllContainerType(), null) )
        {
          headerRow.setAllContainerType(null);
        }
      }

      // 一律条件・容器別条件
      // 一律条件・容器別条件（寄付金登録用）
      if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType) ||
           XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
         )
      {
        // 容器区分設定なし
        if ( allContainerType == null || "".equals(allContainerType) ) 
        {
          // 容器別条件に設定
          allContainerType = XxcsoSpDecisionConstants.CNTNR_SEL;
          if ( isDiffer(headerRow.getAllContainerType(), allContainerType) )
          {
            headerRow.setAllContainerType(allContainerType);
          }
        }

        // 容器別条件初期化用VOを初期化
        ccLineInitVo.initQuery(allContainerType);
        XxcsoSpDecisionCcLineInitVORowImpl ccLineInitRow
          = (XxcsoSpDecisionCcLineInitVORowImpl)ccLineInitVo.first();

        if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
        {
          // 全容器の場合
          if ( allCcRow == null )
          {
            // まだ作成されていない場合は、容器別条件初期化用VOから
            // 全容器明細行を作成する
            while ( ccLineInitRow != null )
            {
              allCcRow
                = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.createRow();

              allCcVo.last();
              allCcVo.next();
              allCcVo.insertRow(allCcRow);

              // 初期値を設定
              allCcRow.setSpContainerType(
                ccLineInitRow.getSpContainerType()
              );
              allCcRow.setDefinedFixedPrice(
                ccLineInitRow.getDefinedFixedPrice()
              );
              allCcRow.setDefinedCostRate(
                ccLineInitRow.getDefinedCostRate()
              );
              allCcRow.setCostPrice(
                ccLineInitRow.getCostPrice()
              );

              ccLineInitRow
                = (XxcsoSpDecisionCcLineInitVORowImpl)ccLineInitVo.next();
            }
          }
        }
        else
        {
          // 容器別条件の場合
          if ( selCcRow == null )
          {
            // まだ作成されていない場合は、容器別条件初期化用VOから
            // 容器別条件明細行を作成する
            while ( ccLineInitRow != null )
            {
              selCcRow
                = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.createRow();

              selCcVo.last();
              selCcVo.next();
              selCcVo.insertRow(selCcRow);

              // 初期値を設定
              selCcRow.setSpContainerType(
                ccLineInitRow.getSpContainerType()
              );
              selCcRow.setDefinedFixedPrice(
                ccLineInitRow.getDefinedFixedPrice()
              );
              selCcRow.setDefinedCostRate(
                ccLineInitRow.getDefinedCostRate()
              );
              selCcRow.setCostPrice(
                ccLineInitRow.getCostPrice()
              );

              ccLineInitRow
                = (XxcsoSpDecisionCcLineInitVORowImpl)ccLineInitVo.next();
            }
          }
        }
      }
    }
  }


  /*****************************************************************************
   * BM1反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param cntrctVo     契約先登録／更新用ビューインスタンス
   * @param bm1Vo        BM1登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectBm1(
    XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBmFormatVOImpl        bmFmtVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();

    String bm1SendType = headerRow.getBm1SendType();

    if ( XxcsoSpDecisionConstants.SEND_SAME_INSTALL.equals(bm1SendType) )
    {
      // 2009-10-14 [IE554,IE573] Add Start
      String Address = "";
      if (installRow.getState() != null)
      {
        Address = Address + installRow.getState();
      }
      if (installRow.getCity() != null)
      {
        Address = Address + installRow.getCity();
      }
      if (installRow.getAddress1() != null)
      {
        Address = Address + installRow.getAddress1();
      }
      if (installRow.getAddress2() != null)
      {
        Address = Address + installRow.getAddress2();
      }
      String Address1 = "";
      String Address2 = "";
      if (Address != null )
      {
        if (Address.length() > 17 )
        {
          Address1 = Address.substring(0,17);
          Address2 = Address.substring(17);
        }
        else
        {
          Address1 = Address;
        }
      }
      // 2009-10-14 [IE554,IE573] Add End
      bmFmtVo.initQuery(
        installRow.getPartyName()
       ,installRow.getPartyNameAlt()
       // 2009-10-14 [IE554,IE573] Add Start
       //,installRow.getState()
       //,installRow.getCity()
       //,installRow.getAddress1()
       //,installRow.getAddress2()
       ,null
       ,null
       ,Address1
       ,Address2
       // 2009-10-14 [IE554,IE573] Add End
      );

      XxcsoSpDecisionBmFormatVORowImpl bmFmtRow
        = (XxcsoSpDecisionBmFormatVORowImpl)bmFmtVo.first();
      
      if ( isDiffer(bm1Row.getCustomerId(), null) )
      {
        bm1Row.setCustomerId(null);
      }
      if ( isDiffer(bm1Row.getVendorNumber(), null) )
      {
        bm1Row.setVendorNumber(null);
      }
      if ( isDiffer(bm1Row.getPartyName(), bmFmtRow.getVendorName()) )
      {
        bm1Row.setPartyName(
          bmFmtRow.getVendorName()
        );
      }
      if ( isDiffer(bm1Row.getPartyNameAlt(), bmFmtRow.getVendorNameAlt()) )
      {
        bm1Row.setPartyNameAlt(
          bmFmtRow.getVendorNameAlt()
        );
      }
      if ( isDiffer(
             bm1Row.getPostalCodeFirst()
            ,installRow.getPostalCodeFirst()
           )
         )
      {
        bm1Row.setPostalCodeFirst(
          installRow.getPostalCodeFirst()
        );
      }
      if ( isDiffer(
             bm1Row.getPostalCodeSecond()
            ,installRow.getPostalCodeSecond()
           )
         )
      {
        bm1Row.setPostalCodeSecond(
          installRow.getPostalCodeSecond()
        );
      }
      if ( isDiffer(bm1Row.getState(), bmFmtRow.getState()) )
      {
        bm1Row.setState(
          bmFmtRow.getState()
        );
      }
      if ( isDiffer(bm1Row.getCity(), bmFmtRow.getCity()) )
      {
        bm1Row.setCity(
          bmFmtRow.getCity()
        );
      }
      if ( isDiffer(bm1Row.getAddress1(), bmFmtRow.getAddress1()) )
      {
        bm1Row.setAddress1(
          bmFmtRow.getAddress1()
        );
      }
      if ( isDiffer(bm1Row.getAddress2(), bmFmtRow.getAddress2()) )
      {
        bm1Row.setAddress2(
          bmFmtRow.getAddress2()
        );
      }
      if ( isDiffer(
             bm1Row.getAddressLinesPhonetic()
            ,installRow.getAddressLinesPhonetic()
           )
         )
      {
        bm1Row.setAddressLinesPhonetic(
          installRow.getAddressLinesPhonetic()
        );
      }
    }

    if ( XxcsoSpDecisionConstants.SEND_SAME_CNTRCT.equals(bm1SendType) )
    {
      // 2009-10-14 [IE554,IE573] Add Start
      String Address = "";
      if (cntrctRow.getState() != null)
      {
        Address = Address + cntrctRow.getState();
      }
      if (cntrctRow.getCity() != null)
      {
        Address = Address + cntrctRow.getCity();
      }
      if (cntrctRow.getAddress1()!= null)
      {
        Address = Address + cntrctRow.getAddress1();
      }
      if (cntrctRow.getAddress2()!= null)
      {
        Address = Address + cntrctRow.getAddress2();
      }
      String Address1 = "";
      String Address2 = "";
      if (Address != null )
      {
        if (Address.length() > 17 )
        {
          Address1 = Address.substring(0,17);
          Address2 = Address.substring(17);
        }
        else
        {
          Address1 = Address;
        }
      }
      // 2009-10-14 [IE554,IE573] Add End
      bmFmtVo.initQuery(
        cntrctRow.getPartyName()
       ,cntrctRow.getPartyNameAlt()
       // 2009-10-14 [IE554,IE573] Add Start
       //,cntrctRow.getState()
       //,cntrctRow.getCity()
       //,cntrctRow.getAddress1()
       //,cntrctRow.getAddress2()
       ,null
       ,null
       ,Address1
       ,Address2
       // 2009-10-14 [IE554,IE573] Add End
      );

      XxcsoSpDecisionBmFormatVORowImpl bmFmtRow
        = (XxcsoSpDecisionBmFormatVORowImpl)bmFmtVo.first();
      
      if ( isDiffer(bm1Row.getCustomerId(), null) )
      {
        bm1Row.setCustomerId(null);
      }
      if ( isDiffer(bm1Row.getVendorNumber(), null) )
      {
        bm1Row.setVendorNumber(null);
      }
      if ( isDiffer(bm1Row.getPartyName(), bmFmtRow.getVendorName()) )
      {
        bm1Row.setPartyName(
          bmFmtRow.getVendorName()
        );
      }
      if ( isDiffer(bm1Row.getPartyNameAlt(), bmFmtRow.getVendorNameAlt()) )
      {
        bm1Row.setPartyNameAlt(
          bmFmtRow.getVendorNameAlt()
        );
      }
      if ( isDiffer(
             bm1Row.getPostalCodeFirst()
            ,cntrctRow.getPostalCodeFirst()
           )
         )
      {
        bm1Row.setPostalCodeFirst(
          cntrctRow.getPostalCodeFirst()
        );
      }
      if ( isDiffer(
             bm1Row.getPostalCodeSecond()
            ,cntrctRow.getPostalCodeSecond()
           )
         )
      {
        bm1Row.setPostalCodeSecond(
          cntrctRow.getPostalCodeSecond()
        );
      }
      if ( isDiffer(bm1Row.getState(), bmFmtRow.getState()) )
      {
        bm1Row.setState(
          bmFmtRow.getState()
        );
      }
      if ( isDiffer(bm1Row.getCity(), bmFmtRow.getCity()) )
      {
        bm1Row.setCity(
          bmFmtRow.getCity()
        );
      }
      if ( isDiffer(bm1Row.getAddress1(), bmFmtRow.getAddress1()) )
      {
        bm1Row.setAddress1(
          bmFmtRow.getAddress1()
        );
      }
      if ( isDiffer(bm1Row.getAddress2(), bmFmtRow.getAddress2()) )
      {
        bm1Row.setAddress2(
          bmFmtRow.getAddress2()
        );
      }
      if ( isDiffer(
             bm1Row.getAddressLinesPhonetic()
            ,cntrctRow.getAddressLinesPhonetic()
           )
         )
      {
        bm1Row.setAddressLinesPhonetic(
          cntrctRow.getAddressLinesPhonetic()
        );
      }
    }

    String vendorNumber = bm1Row.getVendorNumber();

    if ( vendorNumber == null || "".equals(vendorNumber) )
    {
      if ( isDiffer(
             bm1Row.getInquiryBaseCode()
            ,installRow.getPublishBaseCode()
           )
         )
      {
        bm1Row.setInquiryBaseCode(
          installRow.getPublishBaseCode()
        );
      }
      if ( isDiffer(
             bm1Row.getInquiryBaseName()
            ,installRow.getPublishBaseName()
           )
         )
      {
        bm1Row.setInquiryBaseName(
          installRow.getPublishBaseName()
        );
      }
    }
  }


  /*****************************************************************************
   * BM2反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param bm2Vo        BM2登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectBm2(
    XxcsoSpDecisionHeaderFullVOImpl    headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl  installVo
   ,XxcsoSpDecisionBm2CustFullVOImpl   bm2Vo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();

    String vendorNumber = bm2Row.getVendorNumber();

    if ( vendorNumber == null || "".equals(vendorNumber) )
    {
      if ( isDiffer(
             bm2Row.getInquiryBaseCode()
            ,installRow.getPublishBaseCode()
           )
         )
      {
        bm2Row.setInquiryBaseCode(
          installRow.getPublishBaseCode()
        );
      }
      if ( isDiffer(
             bm2Row.getInquiryBaseName()
            ,installRow.getPublishBaseName()
           )
         )
      {
        bm2Row.setInquiryBaseName(
          installRow.getPublishBaseName()
        );
      }
    }
  }



  /*****************************************************************************
   * BM3反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param bm3Vo        BM3登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectBm3(
    XxcsoSpDecisionHeaderFullVOImpl    headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl  installVo
   ,XxcsoSpDecisionBm3CustFullVOImpl   bm3Vo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();

    String vendorNumber = bm3Row.getVendorNumber();

    if ( vendorNumber == null || "".equals(vendorNumber) )
    {
      if ( isDiffer(
             bm3Row.getInquiryBaseCode()
            ,installRow.getPublishBaseCode()
           )
         )
      {
        bm3Row.setInquiryBaseCode(
          installRow.getPublishBaseCode()
        );
      }
      if ( isDiffer(
             bm3Row.getInquiryBaseName()
            ,installRow.getPublishBaseName()
           )
         )
      {
        bm3Row.setInquiryBaseName(
          installRow.getPublishBaseName()
        );
      }
    }
  }



  /*****************************************************************************
   * 契約書への記載事項反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param bm1Vo        BM1登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectContent(
    XxcsoSpDecisionHeaderFullVOImpl    headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl  installVo
   ,XxcsoSpDecisionBm1CustFullVOImpl   bm1Vo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();

    headerRow.setContractYearDateView(
      headerRow.getContractYearDate()
    );
    installRow.setPublishBaseCodeView(
      installRow.getPublishBaseCode()
    );
    installRow.setPublishBaseNameView(
      installRow.getPublishBaseName()
    );
    headerRow.setElectricityTypeView(
      headerRow.getElectricityType()
    );
    headerRow.setElectricityAmountView(
      headerRow.getElectricityAmount()
    );
    bm1Row.setTransferCommissionTypeView(
      bm1Row.getTransferCommissionType()
    );
    headerRow.setInstallSupportAmtView(
      headerRow.getInstallSupportAmt()
    );
    headerRow.setPaymentCycleView(
      headerRow.getPaymentCycle()
    );
    headerRow.setInstallSupportAmt2View(
      headerRow.getInstallSupportAmt2()
    );
  }

// 2009-03-23 [ST障害T1_0163] Add Start
  /*****************************************************************************
   * 電気代区分変更時情報反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectElectricity(
    XxcsoSpDecisionHeaderFullVOImpl    headerVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    String electricityType = headerRow.getElectricityType();
    if ( XxcsoSpDecisionConstants.ELEC_NONE.equals(electricityType) )
    {
      if ( isDiffer(headerRow.getElectricityAmount(), null) )
      {
        headerRow.setElectricityAmount(null);
      }
    }
  }
// 2009-03-23 [ST障害T1_0163] Add End

  /*****************************************************************************
   * 全反映
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param cntrctVo     契約先登録／更新用ビューインスタンス
   * @param bm1Vo        BM1登録／更新用ビューインスタンス
   * @param bm2Vo        BM2登録／更新用ビューインスタンス
   * @param bm3Vo        BM3登録／更新用ビューインスタンス
   * @param scVo         売価別条件登録／更新用ビューインスタンス
   * @param allCcVo      全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo      容器別条件登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void reflectAll(
    XxcsoSpDecisionHeaderFullVOImpl        headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl      installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl    cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl       bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl       bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl       bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl        scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl     allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl     selCcVo
   ,XxcsoSpDecisionBmFormatVOImpl          bmFmtVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    /////////////////////////////////////
    // 値の設定：設置先
    /////////////////////////////////////
    if ( installRow.getPostalCodeFirst() == null       ||
         "".equals(installRow.getPostalCodeFirst())    ||
         installRow.getPostalCodeSecond() == null      ||
         "".equals(installRow.getPostalCodeSecond())
       )
    {
      if ( isDiffer(installRow.getPostalCode(), null) )
      {
        installRow.setPostalCode(null);
      }
    }
    else
    {
      String postalCode
        = installRow.getPostalCodeFirst() + installRow.getPostalCodeSecond();

      if ( isDiffer(installRow.getPostalCode(), postalCode) )
      {
        installRow.setPostalCode(postalCode);
      }
    }

    String customerStatus = installRow.getCustomerStatus();
    if ( customerStatus == null || "".equals(customerStatus) )
    {
      if ( isDiffer(installRow.getNewCustomerFlag(), "Y") )
      {
        installRow.setNewCustomerFlag("Y");
      }
    }
    else
    {
      if ( XxcsoSpDecisionConstants.CUST_STATUS_MC.equals(customerStatus)     ||
           XxcsoSpDecisionConstants.CUST_STATUS_MC_CAND.equals(customerStatus)
         )
      {
        if ( isDiffer(installRow.getNewCustomerFlag(), "Y") )
        {
          installRow.setNewCustomerFlag("Y");
        }
      }
      else
      {
        if ( isDiffer(installRow.getNewCustomerFlag(), "N") )
        {
          installRow.setNewCustomerFlag("N");
        }
      }
    }
    
    /////////////////////////////////////
    // 値の設定：契約先
    /////////////////////////////////////
// 2009-05-26 [ST障害T1_1216] Add Start
    String applicationType = headerRow.getApplicationType();
// 2009-05-26 [ST障害T1_1216] Add End
// 2009-05-19 [ST障害T1_1058] Add Start
    String sameInstAcctFlag = cntrctRow.getSameInstallAccountFlag();
    if ( "Y".equals(sameInstAcctFlag) )
    {
      if ( isDiffer(cntrctRow.getCustomerId(), null) )
      {
        cntrctRow.setCustomerId(null);
      }
      if ( isDiffer(cntrctRow.getContractNumber(), null) )
      {
        cntrctRow.setContractNumber(null);
      }
// 2009-05-26 [ST障害T1_1216] Add Start
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals( applicationType ) )
      {
// 2009-05-26 [ST障害T1_1216] Add End
        if ( isDiffer(cntrctRow.getPartyName(), installRow.getPartyName()) )
        {
          cntrctRow.setPartyName(
            installRow.getPartyName()
          );
        }
// 2009-05-26 [ST障害T1_1216] Add Start
      }
// 2009-05-26 [ST障害T1_1216] Add End
// 2009-05-26 [ST障害T1_1216] Add Start
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals( applicationType ) )
      {
// 2009-05-26 [ST障害T1_1216] Add End
        if ( isDiffer(cntrctRow.getPartyNameAlt(), installRow.getPartyNameAlt()) )
        {
          cntrctRow.setPartyNameAlt(
            installRow.getPartyNameAlt()
          );
        }
// 2009-05-26 [ST障害T1_1216] Add Start
      }
// 2009-05-26 [ST障害T1_1216] Add End
      if ( isDiffer(
             cntrctRow.getPostalCodeFirst()
            ,installRow.getPostalCodeFirst()
           )
         )
      {
        cntrctRow.setPostalCodeFirst(
          installRow.getPostalCodeFirst()
        );
      }
      if ( isDiffer(
             cntrctRow.getPostalCodeSecond()
            ,installRow.getPostalCodeSecond()
           )
         )
      {
        cntrctRow.setPostalCodeSecond(
          installRow.getPostalCodeSecond()
        );
      }
      if ( isDiffer(cntrctRow.getState(), installRow.getState()) )
      {
        cntrctRow.setState(
          installRow.getState()
        );
      }
      if ( isDiffer(cntrctRow.getCity(), installRow.getCity()) )
      {
        cntrctRow.setCity(
          installRow.getCity()
        );
      }
      if ( isDiffer(cntrctRow.getAddress1(), installRow.getAddress1()) )
      {
        cntrctRow.setAddress1(
          installRow.getAddress1()
        );
      }
      if ( isDiffer(cntrctRow.getAddress2(), installRow.getAddress2()) )
      {
        cntrctRow.setAddress2(
          installRow.getAddress2()
        );
      }
      if ( isDiffer(
             cntrctRow.getAddressLinesPhonetic()
            ,installRow.getAddressLinesPhonetic()
           )
         )
      {
        cntrctRow.setAddressLinesPhonetic(
          installRow.getAddressLinesPhonetic()
        );
      }
    }
// 2009-05-19 [ST障害T1_1058] Add End
    if ( cntrctRow.getPostalCodeFirst() == null       ||
         "".equals(cntrctRow.getPostalCodeFirst())    ||
         cntrctRow.getPostalCodeSecond() == null      ||
         "".equals(cntrctRow.getPostalCodeSecond())
       )
    {
      if ( isDiffer(cntrctRow.getPostalCode(), null) )
      {
        cntrctRow.setPostalCode(null);
      }
    }
    else
    {
      String postalCode
        = cntrctRow.getPostalCodeFirst() + cntrctRow.getPostalCodeSecond();
        
      if ( isDiffer(cntrctRow.getPostalCode(), postalCode) )
      {
        cntrctRow.setPostalCode(postalCode);
      }
    }

    /////////////////////////////////////
    // 値の設定：取引条件
    /////////////////////////////////////
    String condBizType = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();
    
    // NULLの場合は全部削除
    if ( condBizType == null || "".equals(condBizType) )
    {
      if ( isDiffer(headerRow.getAllContainerType(), null) )
      {
        condBizType = null;
        headerRow.setAllContainerType(null);
      }
    }

    if ( condBizType == null ||
         XxcsoSpDecisionConstants.COND_NON_PAY_BM.equals(condBizType)
       )
    {
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
      while ( scRow != null )
      {
        scVo.removeCurrentRow();
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
      while ( allCcRow != null )
      {
        allCcVo.removeCurrentRow();
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
      }

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
      while ( selCcRow != null )
      {
        selCcVo.removeCurrentRow();
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
      }
    }

    // 売価別条件の場合は、全容器一律条件、容器別条件を削除
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)            ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( isDiffer(headerRow.getAllContainerType(), null) )
      {
        headerRow.setAllContainerType(null);
      }
      
      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
      while ( allCcRow != null )
      {
        allCcVo.removeCurrentRow();
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
      }

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
      while ( selCcRow != null )
      {
        selCcVo.removeCurrentRow();
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
      }
    }

    // 一律条件・容器別条件の場合は、売価別条件を削除
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)            ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
      while ( scRow != null )
      {
        scVo.removeCurrentRow();
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }

      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        // 全容器一律条件の場合は、容器別条件を削除
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
        while ( selCcRow != null )
        {
          selCcVo.removeCurrentRow();
          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
        }
      }
      else
      {
        // 容器別条件の場合は、全容器一律条件を削除
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
        while ( allCcRow != null )
        {
          allCcVo.removeCurrentRow();
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
        }
      }
    }
    
    /////////////////////////////////////
    // 値の設定：その他条件
    /////////////////////////////////////
    String electricityType = headerRow.getElectricityType();
// 2009-03-23 [ST障害T1_0163] Mod Start
//    if ( electricityType == null || "".equals(electricityType) )
//    {
    if ( XxcsoSpDecisionConstants.ELEC_NONE.equals(electricityType) )
    {
// 2009-03-23 [ST障害T1_0163] Mod End
      if ( isDiffer(headerRow.getElectricityAmount(), null) )
      {
        headerRow.setElectricityAmount(null);
      }
    }
    /////////////////////////////////////
    // 値の設定：BM1/BM2/BM3
    /////////////////////////////////////
    String bizCondType = installRow.getBusinessConditionType();
    if ( XxcsoSpDecisionConstants.BIZ_COND_OFF_SET_VD.equals(bizCondType) )
    {
      String paymentType = XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE;
      if ( isDiffer(bm1Row.getBmPaymentType(), paymentType) )
      {
        bm1Row.setBmPaymentType(paymentType);
      }
      if ( isDiffer(bm2Row.getBmPaymentType(), paymentType) )
      {
        bm2Row.setBmPaymentType(paymentType);
      }
      if ( isDiffer(bm3Row.getBmPaymentType(), paymentType) )
      {
        bm3Row.setBmPaymentType(paymentType);
      }
    }
    
    /////////////////////////////////////
    // 値の設定：BM1
    /////////////////////////////////////
    String bm1PaymentType = bm1Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
    {
      if ( isDiffer(headerRow.getBm1SendType(), null) )
      {
        headerRow.setBm1SendType(null);
      }
      if ( isDiffer(bm1Row.getVendorNumber(), null) )
      {
        bm1Row.setVendorNumber(null);
      }
      if ( isDiffer(bm1Row.getCustomerId(), null) )
      {
        bm1Row.setCustomerId(null);
      }
      if ( isDiffer(bm1Row.getPartyName(), null) )
      {
        bm1Row.setPartyName(null);
      }
      if ( isDiffer(bm1Row.getPartyNameAlt(), null) )
      {
        bm1Row.setPartyNameAlt(null);
      }
      if ( isDiffer(bm1Row.getPostalCodeFirst(), null) )
      {
        bm1Row.setPostalCodeFirst(null);
      }
      if ( isDiffer(bm1Row.getPostalCodeSecond(), null) )
      {
        bm1Row.setPostalCodeSecond(null);
      }
      if ( isDiffer(bm1Row.getPostalCode(), null) )
      {
        bm1Row.setPostalCode(null);
      }
      if ( isDiffer(bm1Row.getState(), null) )
      {
        bm1Row.setState(null);
      }
      if ( isDiffer(bm1Row.getCity(), null) )
      {
        bm1Row.setCity(null);
      }
      if ( isDiffer(bm1Row.getAddress1(), null) )
      {
        bm1Row.setAddress1(null);
      }
      if ( isDiffer(bm1Row.getAddress2(), null) )
      {
        bm1Row.setAddress2(null);
      }
      if ( isDiffer(bm1Row.getAddressLinesPhonetic(), null) )
      {
        bm1Row.setAddressLinesPhonetic(null);
      }
      if ( isDiffer(bm1Row.getTransferCommissionType(), null) )
      {
        bm1Row.setTransferCommissionType(null);
      }
      if ( isDiffer(bm1Row.getInquiryBaseCode(), null) )
      {
        bm1Row.setInquiryBaseCode(null);
      }
      if ( isDiffer(bm1Row.getInquiryBaseName(), null) )
      {
        bm1Row.setInquiryBaseName(null);
      }
    }
    else
    {
      reflectBm1(headerVo, installVo, cntrctVo, bm1Vo, bmFmtVo);
      if ( bm1Row.getPostalCodeFirst() == null       ||
           "".equals(bm1Row.getPostalCodeFirst())    ||
           bm1Row.getPostalCodeSecond() == null      ||
           "".equals(bm1Row.getPostalCodeSecond())
         )
      {
        if ( isDiffer(bm1Row.getPostalCode(), null) )
        {
          bm1Row.setPostalCode(null);
        }
      }
      else
      {
        String postalCode
          = bm1Row.getPostalCodeFirst() + bm1Row.getPostalCodeSecond();

        if ( isDiffer(bm1Row.getPostalCode(), postalCode) )
        {
          bm1Row.setPostalCode(postalCode);
        }
      }
    }

    /////////////////////////////////////
    // 値の設定：BM2
    /////////////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
    {
      if ( isDiffer(bm2Row.getVendorNumber(), null) )
      {
        bm2Row.setVendorNumber(null);
      }
      if ( isDiffer(bm2Row.getCustomerId(), null) )
      {
        bm2Row.setCustomerId(null);
      }
      if ( isDiffer(bm2Row.getPartyName(), null) )
      {
        bm2Row.setPartyName(null);
      }
      if ( isDiffer(bm2Row.getPartyNameAlt(), null) )
      {
        bm2Row.setPartyNameAlt(null);
      }
      if ( isDiffer(bm2Row.getPostalCodeFirst(), null) )
      {
        bm2Row.setPostalCodeFirst(null);
      }
      if ( isDiffer(bm2Row.getPostalCodeSecond(), null) )
      {
        bm2Row.setPostalCodeSecond(null);
      }
      if ( isDiffer(bm2Row.getPostalCode(), null) )
      {
        bm2Row.setPostalCode(null);
      }
      if ( isDiffer(bm2Row.getState(), null) )
      {
        bm2Row.setState(null);
      }
      if ( isDiffer(bm2Row.getCity(), null) )
      {
        bm2Row.setCity(null);
      }
      if ( isDiffer(bm2Row.getAddress1(), null) )
      {
        bm2Row.setAddress1(null);
      }
      if ( isDiffer(bm2Row.getAddress2(), null) )
      {
        bm2Row.setAddress2(null);
      }
      if ( isDiffer(bm2Row.getAddressLinesPhonetic(), null) )
      {
        bm2Row.setAddressLinesPhonetic(null);
      }
      if ( isDiffer(bm2Row.getTransferCommissionType(), null) )
      {
        bm2Row.setTransferCommissionType(null);
      }
      if ( isDiffer(bm2Row.getInquiryBaseCode(), null) )
      {
        bm2Row.setInquiryBaseCode(null);
      }
      if ( isDiffer(bm2Row.getInquiryBaseName(), null) )
      {
        bm2Row.setInquiryBaseName(null);
      }
    }
    else
    {
      reflectBm2(headerVo, installVo, bm2Vo);
      if ( bm2Row.getPostalCodeFirst() == null       ||
           "".equals(bm2Row.getPostalCodeFirst())    ||
           bm2Row.getPostalCodeSecond() == null      ||
           "".equals(bm2Row.getPostalCodeSecond())
         )
      {
        if ( isDiffer(bm2Row.getPostalCode(), null) )
        {
          bm2Row.setPostalCode(null);
        }
      }
      else
      {
        String postalCode
          = bm2Row.getPostalCodeFirst() + bm2Row.getPostalCodeSecond();

        if ( isDiffer(bm2Row.getPostalCode(), postalCode) )
        {
          bm2Row.setPostalCode(postalCode);
        }
      }
    }

    /////////////////////////////////////
    // 値の設定：BM3
    /////////////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
    {
      if ( isDiffer(bm3Row.getVendorNumber(), null) )
      {
        bm3Row.setVendorNumber(null);
      }
      if ( isDiffer(bm3Row.getCustomerId(), null) )
      {
        bm3Row.setCustomerId(null);
      }
      if ( isDiffer(bm3Row.getPartyName(), null) )
      {
        bm3Row.setPartyName(null);
      }
      if ( isDiffer(bm3Row.getPartyNameAlt(), null) )
      {
        bm3Row.setPartyNameAlt(null);
      }
      if ( isDiffer(bm3Row.getPostalCodeFirst(), null) )
      {
        bm3Row.setPostalCodeFirst(null);
      }
      if ( isDiffer(bm3Row.getPostalCodeSecond(), null) )
      {
        bm3Row.setPostalCodeSecond(null);
      }
      if ( isDiffer(bm3Row.getPostalCode(), null) )
      {
        bm3Row.setPostalCode(null);
      }
      if ( isDiffer(bm3Row.getState(), null) )
      {
        bm3Row.setState(null);
      }
      if ( isDiffer(bm3Row.getCity(), null) )
      {
        bm3Row.setCity(null);
      }
      if ( isDiffer(bm3Row.getAddress1(), null) )
      {
        bm3Row.setAddress1(null);
      }
      if ( isDiffer(bm3Row.getAddress2(), null) )
      {
        bm3Row.setAddress2(null);
      }
      if ( isDiffer(bm3Row.getAddressLinesPhonetic(), null) )
      {
        bm3Row.setAddressLinesPhonetic(null);
      }
      if ( isDiffer(bm3Row.getTransferCommissionType(), null) )
      {
        bm3Row.setTransferCommissionType(null);
      }
      if ( isDiffer(bm3Row.getInquiryBaseCode(), null) )
      {
        bm3Row.setInquiryBaseCode(null);
      }
      if ( isDiffer(bm3Row.getInquiryBaseName(), null) )
      {
        bm3Row.setInquiryBaseName(null);
      }
    }
    else
    {
      reflectBm3(headerVo, installVo, bm3Vo);
      if ( bm3Row.getPostalCodeFirst() == null       ||
           "".equals(bm3Row.getPostalCodeFirst())    ||
           bm3Row.getPostalCodeSecond() == null      ||
           "".equals(bm3Row.getPostalCodeSecond())
         )
      {
        if ( isDiffer(bm3Row.getPostalCode(), null) )
        {
          bm3Row.setPostalCode(null);
        }
      }
      else
      {
        String postalCode
          = bm3Row.getPostalCodeFirst() + bm3Row.getPostalCodeSecond();

        if ( isDiffer(bm3Row.getPostalCode(), postalCode) )
        {
          bm3Row.setPostalCode(postalCode);
        }
      }
    }
  }


  /*****************************************************************************
   * 値変換
   * @param txn          OADBTransactionインスタンス
   * @param headerVo     SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo    設置先登録／更新用ビューインスタンス
   * @param cntrctVo     契約先登録／更新用ビューインスタンス
   * @param bm1Vo        BM1登録／更新用ビューインスタンス
   * @param bm2Vo        BM2登録／更新用ビューインスタンス
   * @param bm3Vo        BM3登録／更新用ビューインスタンス
   * @param scVo         売価別条件登録／更新用ビューインスタンス
   * @param allCcVo      全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo      容器別条件登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void convValue(
    OADBTransaction                      txn
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    ////////////////////////////
    // BM1 問合せ担当拠点
    ////////////////////////////
    String bm1PaymentType = bm1Row.getBmPaymentType();
    Number bm1VendorId    = bm1Row.getCustomerId();
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
    {
      if ( bm1VendorId == null )
      {
        String inqBaseCode = bm1Row.getInquiryBaseCode();
        String pubBaseCode = installRow.getPublishBaseCode();
        if ( isDiffer(inqBaseCode, pubBaseCode) )
        {
          bm1Row.setInquiryBaseCode(pubBaseCode);
        }

        String inqBaseName = bm1Row.getInquiryBaseName();
        String pubBaseName = installRow.getPublishBaseName();
        if ( isDiffer(inqBaseName, pubBaseName) )
        {
          bm1Row.setInquiryBaseName(pubBaseName);
        }
      }
    }

    ////////////////////////////
    // BM2 問合せ担当拠点
    ////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    Number bm2VendorId    = bm2Row.getCustomerId();
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
    {
      if ( bm2VendorId == null )
      {
        String inqBaseCode = bm2Row.getInquiryBaseCode();
        String pubBaseCode = installRow.getPublishBaseCode();
        if ( isDiffer(inqBaseCode, pubBaseCode) )
        {
          bm2Row.setInquiryBaseCode(pubBaseCode);
        }

        String inqBaseName = bm2Row.getInquiryBaseName();
        String pubBaseName = installRow.getPublishBaseName();
        if ( isDiffer(inqBaseName, pubBaseName) )
        {
          bm2Row.setInquiryBaseName(pubBaseName);
        }
      }
    }

    ////////////////////////////
    // BM3 問合せ担当拠点
    ////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    Number bm3VendorId    = bm3Row.getCustomerId();
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
    {
      if ( bm3VendorId == null )
      {
        String inqBaseCode = bm3Row.getInquiryBaseCode();
        String pubBaseCode = installRow.getPublishBaseCode();
        if ( isDiffer(inqBaseCode, pubBaseCode) )
        {
          bm3Row.setInquiryBaseCode(pubBaseCode);
        }

        String inqBaseName = bm3Row.getInquiryBaseName();
        String pubBaseName = installRow.getPublishBaseName();
        if ( isDiffer(inqBaseName, pubBaseName) )
        {
          bm3Row.setInquiryBaseName(pubBaseName);
        }
      }
    }
    
    ////////////////////////////
    // ヘッダ項目数値フォーマット変換
    ////////////////////////////
    String seleNumber          = headerRow.getSeleNumber();
    String contractYearDate    = headerRow.getContractYearDate();
    String installSupportAmt   = headerRow.getInstallSupportAmt();
    String installSupportAmt2  = headerRow.getInstallSupportAmt2();
    String paymentCycle        = headerRow.getPaymentCycle();
    String electricityAmount   = headerRow.getElectricityAmount();
    String salesMonth          = headerRow.getSalesMonth();
    String bmRate              = headerRow.getBmRate();
    String vdSalesCharge       = headerRow.getVdSalesCharge();
    String leaseChargeMonth    = headerRow.getLeaseChargeMonth();
    String constructionCharge  = headerRow.getConstructionCharge();
    String electricityAmtMonth = headerRow.getElectricityAmtMonth();

    CallableStatement stmt = null;
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.conv_number_separate(");
      sql.append("    :1,  :2,  :3,  :4,  :5,  :6,  :7 , :8,  :9,  :10,");
      sql.append("    :11, :12, :13, :14, :15, :16, :17, :18, :19, :20,");
      sql.append("    :21, :22, :23, :24");
      sql.append("  );");
      sql.append("END;");

      stmt = txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1,  seleNumber);
      stmt.setString(2,  contractYearDate);
      stmt.setString(3,  installSupportAmt);
      stmt.setString(4,  installSupportAmt2);
      stmt.setString(5,  paymentCycle);
      stmt.setString(6,  electricityAmount);
      stmt.setString(7,  salesMonth);
      stmt.setString(8,  bmRate);
      stmt.setString(9,  vdSalesCharge);
      stmt.setString(10, leaseChargeMonth);
      stmt.setString(11, constructionCharge);
      stmt.setString(12, electricityAmtMonth);

      stmt.registerOutParameter(13, Types.VARCHAR);
      stmt.registerOutParameter(14, Types.VARCHAR);
      stmt.registerOutParameter(15, Types.VARCHAR);
      stmt.registerOutParameter(16, Types.VARCHAR);
      stmt.registerOutParameter(17, Types.VARCHAR);
      stmt.registerOutParameter(18, Types.VARCHAR);
      stmt.registerOutParameter(19, Types.VARCHAR);
      stmt.registerOutParameter(20, Types.VARCHAR);
      stmt.registerOutParameter(21, Types.VARCHAR);
      stmt.registerOutParameter(22, Types.VARCHAR);
      stmt.registerOutParameter(23, Types.VARCHAR);
      stmt.registerOutParameter(24, Types.VARCHAR);

      stmt.execute();

      String cnvSeleNumber          = stmt.getString(13);
      String cnvContractYearDate    = stmt.getString(14);
      String cnvInstallSupportAmt   = stmt.getString(15);
      String cnvInstallSupportAmt2  = stmt.getString(16);
      String cnvPaymentCycle        = stmt.getString(17);
      String cnvElectricityAmount   = stmt.getString(18);
      String cnvSalesMonth          = stmt.getString(19);
      String cnvBmRate              = stmt.getString(20);
      String cnvVdSalesCharge       = stmt.getString(21);
      String cnvLeaseChargeMonth    = stmt.getString(22);
      String cnvConstructionCharge  = stmt.getString(23);
      String cnvElectricityAmtMonth = stmt.getString(24);

      if ( isDiffer(seleNumber, cnvSeleNumber) )
      {
        headerRow.setSeleNumber(cnvSeleNumber);
      }
      if ( isDiffer(contractYearDate, cnvContractYearDate) )
      {
        headerRow.setContractYearDate(cnvContractYearDate);
      }
      if ( isDiffer(installSupportAmt, cnvInstallSupportAmt) )
      {
        headerRow.setInstallSupportAmt(cnvInstallSupportAmt);
      }
      if ( isDiffer(installSupportAmt2, cnvInstallSupportAmt2) )
      {
        headerRow.setInstallSupportAmt2(cnvInstallSupportAmt2);
      }
      if ( isDiffer(paymentCycle, cnvPaymentCycle) )
      {
        headerRow.setPaymentCycle(cnvPaymentCycle);
      }
      if ( isDiffer(electricityAmount, cnvElectricityAmount) )
      {
        headerRow.setElectricityAmount(cnvElectricityAmount);
      }
      if ( isDiffer(salesMonth, cnvSalesMonth) )
      {
        headerRow.setSalesMonth(cnvSalesMonth);
      }
      if ( isDiffer(bmRate, cnvBmRate) )
      {
        headerRow.setBmRate(cnvBmRate);
      }
      if ( isDiffer(vdSalesCharge, cnvVdSalesCharge) )
      {
        headerRow.setVdSalesCharge(cnvVdSalesCharge);
      }
      if ( isDiffer(leaseChargeMonth, cnvLeaseChargeMonth) )
      {
        headerRow.setLeaseChargeMonth(cnvLeaseChargeMonth);
      }
      if ( isDiffer(constructionCharge, cnvConstructionCharge) )
      {
        headerRow.setConstructionCharge(cnvConstructionCharge);
      }
      if ( isDiffer(electricityAmtMonth, cnvElectricityAmtMonth) )
      {
        headerRow.setElectricityAmtMonth(cnvElectricityAmtMonth);
      }

      stmt.close();
      sql.delete(0, sql.length());

      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.conv_line_number_separate(");
      sql.append("    :1,  :2,  :3,  :4,  :5,  :6,  :7 , :8,  :9,  :10,");
      sql.append("    :11, :12, :13, :14, :15, :16, :17, :18, :19, :20,");
      sql.append("    :21, :22");
      sql.append("  );");
      sql.append("END;");

      stmt = txn.createCallableStatement(sql.toString(), 0);

      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
      while ( scRow != null )
      {
        String salesPrice      = scRow.getSalesPrice();
        String discountAmt     = scRow.getDiscountAmt();
        String totalBmRate     = scRow.getBmRatePerSalesPrice();
        String totalBmAmount   = scRow.getBmAmountPerSalesPrice();
        String totalBmConvRate = scRow.getBmConvRatePerSalesPrice();
        String bm1BmRate       = scRow.getBm1BmRate();
        String bm1BmAmount     = scRow.getBm1BmAmount();
        String bm2BmRate       = scRow.getBm2BmRate();
        String bm2BmAmount     = scRow.getBm2BmAmount();
        String bm3BmRate       = scRow.getBm3BmRate();
        String bm3BmAmount     = scRow.getBm3BmAmount();

        stmt.setString(1,  salesPrice);
        stmt.setString(2,  discountAmt);
        stmt.setString(3,  totalBmRate);
        stmt.setString(4,  totalBmAmount);
        stmt.setString(5,  totalBmConvRate);
        stmt.setString(6,  bm1BmRate);
        stmt.setString(7,  bm1BmAmount);
        stmt.setString(8,  bm2BmRate);
        stmt.setString(9,  bm2BmAmount);
        stmt.setString(10, bm3BmRate);
        stmt.setString(11, bm3BmAmount);

        stmt.registerOutParameter(12, Types.VARCHAR);
        stmt.registerOutParameter(13, Types.VARCHAR);
        stmt.registerOutParameter(14, Types.VARCHAR);
        stmt.registerOutParameter(15, Types.VARCHAR);
        stmt.registerOutParameter(16, Types.VARCHAR);
        stmt.registerOutParameter(17, Types.VARCHAR);
        stmt.registerOutParameter(18, Types.VARCHAR);
        stmt.registerOutParameter(19, Types.VARCHAR);
        stmt.registerOutParameter(20, Types.VARCHAR);
        stmt.registerOutParameter(21, Types.VARCHAR);
        stmt.registerOutParameter(22, Types.VARCHAR);

        stmt.execute();

        String cnvSalesPrice      = stmt.getString(12);
        String cnvDiscountAmt     = stmt.getString(13);
        String cnvTotalBmRate     = stmt.getString(14);
        String cnvTotalBmAmount   = stmt.getString(15);
        String cnvTotalBmConvRate = stmt.getString(16);
        String cnvBm1BmRate       = stmt.getString(17);
        String cnvBm1BmAmount     = stmt.getString(18);
        String cnvBm2BmRate       = stmt.getString(19);
        String cnvBm2BmAmount     = stmt.getString(20);
        String cnvBm3BmRate       = stmt.getString(21);
        String cnvBm3BmAmount     = stmt.getString(22);

        if ( isDiffer(salesPrice, cnvSalesPrice) )
        {
          scRow.setSalesPrice(cnvSalesPrice);
        }
        if ( isDiffer(discountAmt, cnvDiscountAmt) )
        {
          scRow.setDiscountAmt(cnvDiscountAmt);
        }
        if ( isDiffer(totalBmRate, cnvTotalBmRate) )
        {
          scRow.setBmRatePerSalesPrice(cnvTotalBmRate);
        }
        if ( isDiffer(totalBmAmount, cnvTotalBmAmount) )
        {
          scRow.setBmAmountPerSalesPrice(cnvTotalBmAmount);
        }
        if ( isDiffer(totalBmConvRate, cnvTotalBmConvRate) )
        {
          scRow.setBmConvRatePerSalesPrice(cnvTotalBmConvRate);
        }
        if ( isDiffer(bm1BmRate, cnvBm1BmRate) )
        {
          scRow.setBm1BmRate(cnvBm1BmRate);
        }
        if ( isDiffer(bm1BmAmount, cnvBm1BmAmount) )
        {
          scRow.setBm1BmAmount(cnvBm1BmAmount);
        }
        if ( isDiffer(bm2BmRate, cnvBm2BmRate) )
        {
          scRow.setBm2BmRate(cnvBm2BmRate);
        }
        if ( isDiffer(bm2BmAmount, cnvBm2BmAmount) )
        {
          scRow.setBm2BmAmount(cnvBm2BmAmount);
        }
        if ( isDiffer(bm3BmRate, cnvBm3BmRate) )
        {
          scRow.setBm3BmRate(cnvBm3BmRate);
        }
        if ( isDiffer(bm3BmAmount, cnvBm3BmAmount) )
        {
          scRow.setBm3BmAmount(cnvBm3BmAmount);
        }
        
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
      while ( allCcRow != null )
      {
        String salesPrice      = allCcRow.getSalesPrice();
        String discountAmt     = allCcRow.getDiscountAmt();
        String totalBmRate     = allCcRow.getBmRatePerSalesPrice();
        String totalBmAmount   = allCcRow.getBmAmountPerSalesPrice();
        String totalBmConvRate = allCcRow.getBmConvRatePerSalesPrice();
        String bm1BmRate       = allCcRow.getBm1BmRate();
        String bm1BmAmount     = allCcRow.getBm1BmAmount();
        String bm2BmRate       = allCcRow.getBm2BmRate();
        String bm2BmAmount     = allCcRow.getBm2BmAmount();
        String bm3BmRate       = allCcRow.getBm3BmRate();
        String bm3BmAmount     = allCcRow.getBm3BmAmount();

        stmt.setString(1,  salesPrice);
        stmt.setString(2,  discountAmt);
        stmt.setString(3,  totalBmRate);
        stmt.setString(4,  totalBmAmount);
        stmt.setString(5,  totalBmConvRate);
        stmt.setString(6,  bm1BmRate);
        stmt.setString(7,  bm1BmAmount);
        stmt.setString(8,  bm2BmRate);
        stmt.setString(9,  bm2BmAmount);
        stmt.setString(10, bm3BmRate);
        stmt.setString(11, bm3BmAmount);

        stmt.registerOutParameter(12, Types.VARCHAR);
        stmt.registerOutParameter(13, Types.VARCHAR);
        stmt.registerOutParameter(14, Types.VARCHAR);
        stmt.registerOutParameter(15, Types.VARCHAR);
        stmt.registerOutParameter(16, Types.VARCHAR);
        stmt.registerOutParameter(17, Types.VARCHAR);
        stmt.registerOutParameter(18, Types.VARCHAR);
        stmt.registerOutParameter(19, Types.VARCHAR);
        stmt.registerOutParameter(20, Types.VARCHAR);
        stmt.registerOutParameter(21, Types.VARCHAR);
        stmt.registerOutParameter(22, Types.VARCHAR);

        stmt.execute();

        String cnvSalesPrice      = stmt.getString(12);
        String cnvDiscountAmt     = stmt.getString(13);
        String cnvTotalBmRate     = stmt.getString(14);
        String cnvTotalBmAmount   = stmt.getString(15);
        String cnvTotalBmConvRate = stmt.getString(16);
        String cnvBm1BmRate       = stmt.getString(17);
        String cnvBm1BmAmount     = stmt.getString(18);
        String cnvBm2BmRate       = stmt.getString(19);
        String cnvBm2BmAmount     = stmt.getString(20);
        String cnvBm3BmRate       = stmt.getString(21);
        String cnvBm3BmAmount     = stmt.getString(22);

        if ( isDiffer(salesPrice, cnvSalesPrice) )
        {
          allCcRow.setSalesPrice(cnvSalesPrice);
        }
        if ( isDiffer(discountAmt, cnvDiscountAmt) )
        {
          allCcRow.setDiscountAmt(cnvDiscountAmt);
        }
        if ( isDiffer(totalBmRate, cnvTotalBmRate) )
        {
          allCcRow.setBmRatePerSalesPrice(cnvTotalBmRate);
        }
        if ( isDiffer(totalBmAmount, cnvTotalBmAmount) )
        {
          allCcRow.setBmAmountPerSalesPrice(cnvTotalBmAmount);
        }
        if ( isDiffer(totalBmConvRate, cnvTotalBmConvRate) )
        {
          allCcRow.setBmConvRatePerSalesPrice(cnvTotalBmConvRate);
        }
        if ( isDiffer(bm1BmRate, cnvBm1BmRate) )
        {
          allCcRow.setBm1BmRate(cnvBm1BmRate);
        }
        if ( isDiffer(bm1BmAmount, cnvBm1BmAmount) )
        {
          allCcRow.setBm1BmAmount(cnvBm1BmAmount);
        }
        if ( isDiffer(bm2BmRate, cnvBm2BmRate) )
        {
          allCcRow.setBm2BmRate(cnvBm2BmRate);
        }
        if ( isDiffer(bm2BmAmount, cnvBm2BmAmount) )
        {
          allCcRow.setBm2BmAmount(cnvBm2BmAmount);
        }
        if ( isDiffer(bm3BmRate, cnvBm3BmRate) )
        {
          allCcRow.setBm3BmRate(cnvBm3BmRate);
        }
        if ( isDiffer(bm3BmAmount, cnvBm3BmAmount) )
        {
          allCcRow.setBm3BmAmount(cnvBm3BmAmount);
        }
        
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
      }

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
      while ( selCcRow != null )
      {
        String salesPrice      = selCcRow.getSalesPrice();
        String discountAmt     = selCcRow.getDiscountAmt();
        String totalBmRate     = selCcRow.getBmRatePerSalesPrice();
        String totalBmAmount   = selCcRow.getBmAmountPerSalesPrice();
        String totalBmConvRate = selCcRow.getBmConvRatePerSalesPrice();
        String bm1BmRate       = selCcRow.getBm1BmRate();
        String bm1BmAmount     = selCcRow.getBm1BmAmount();
        String bm2BmRate       = selCcRow.getBm2BmRate();
        String bm2BmAmount     = selCcRow.getBm2BmAmount();
        String bm3BmRate       = selCcRow.getBm3BmRate();
        String bm3BmAmount     = selCcRow.getBm3BmAmount();

        stmt.setString(1,  salesPrice);
        stmt.setString(2,  discountAmt);
        stmt.setString(3,  totalBmRate);
        stmt.setString(4,  totalBmAmount);
        stmt.setString(5,  totalBmConvRate);
        stmt.setString(6,  bm1BmRate);
        stmt.setString(7,  bm1BmAmount);
        stmt.setString(8,  bm2BmRate);
        stmt.setString(9,  bm2BmAmount);
        stmt.setString(10, bm3BmRate);
        stmt.setString(11, bm3BmAmount);

        stmt.registerOutParameter(12, Types.VARCHAR);
        stmt.registerOutParameter(13, Types.VARCHAR);
        stmt.registerOutParameter(14, Types.VARCHAR);
        stmt.registerOutParameter(15, Types.VARCHAR);
        stmt.registerOutParameter(16, Types.VARCHAR);
        stmt.registerOutParameter(17, Types.VARCHAR);
        stmt.registerOutParameter(18, Types.VARCHAR);
        stmt.registerOutParameter(19, Types.VARCHAR);
        stmt.registerOutParameter(20, Types.VARCHAR);
        stmt.registerOutParameter(21, Types.VARCHAR);
        stmt.registerOutParameter(22, Types.VARCHAR);

        stmt.execute();

        String cnvSalesPrice      = stmt.getString(12);
        String cnvDiscountAmt     = stmt.getString(13);
        String cnvTotalBmRate     = stmt.getString(14);
        String cnvTotalBmAmount   = stmt.getString(15);
        String cnvTotalBmConvRate = stmt.getString(16);
        String cnvBm1BmRate       = stmt.getString(17);
        String cnvBm1BmAmount     = stmt.getString(18);
        String cnvBm2BmRate       = stmt.getString(19);
        String cnvBm2BmAmount     = stmt.getString(20);
        String cnvBm3BmRate       = stmt.getString(21);
        String cnvBm3BmAmount     = stmt.getString(22);

        if ( isDiffer(salesPrice, cnvSalesPrice) )
        {
          selCcRow.setSalesPrice(cnvSalesPrice);
        }
        if ( isDiffer(discountAmt, cnvDiscountAmt) )
        {
          selCcRow.setDiscountAmt(cnvDiscountAmt);
        }
        if ( isDiffer(totalBmRate, cnvTotalBmRate) )
        {
          selCcRow.setBmRatePerSalesPrice(cnvTotalBmRate);
        }
        if ( isDiffer(totalBmAmount, cnvTotalBmAmount) )
        {
          selCcRow.setBmAmountPerSalesPrice(cnvTotalBmAmount);
        }
        if ( isDiffer(totalBmConvRate, cnvTotalBmConvRate) )
        {
          selCcRow.setBmConvRatePerSalesPrice(cnvTotalBmConvRate);
        }
        if ( isDiffer(bm1BmRate, cnvBm1BmRate) )
        {
          selCcRow.setBm1BmRate(cnvBm1BmRate);
        }
        if ( isDiffer(bm1BmAmount, cnvBm1BmAmount) )
        {
          selCcRow.setBm1BmAmount(cnvBm1BmAmount);
        }
        if ( isDiffer(bm2BmRate, cnvBm2BmRate) )
        {
          selCcRow.setBm2BmRate(cnvBm2BmRate);
        }
        if ( isDiffer(bm2BmAmount, cnvBm2BmAmount) )
        {
          selCcRow.setBm2BmAmount(cnvBm2BmAmount);
        }
        if ( isDiffer(bm3BmRate, cnvBm3BmRate) )
        {
          selCcRow.setBm3BmRate(cnvBm3BmRate);
        }
        if ( isDiffer(bm3BmAmount, cnvBm3BmAmount) )
        {
          selCcRow.setBm3BmAmount(cnvBm3BmAmount);
        }
        
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONV_NUMBER_SEPARATE
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
  }


  /*****************************************************************************
   * 差分確認（String）
   * @param org          オリジナル
   * @param copy         設定値
   *****************************************************************************
   */
  public static boolean isDiffer(
    String  org
   ,String  copy
  )
  {
    boolean diff = true;
    
    if ( org == null )
    {
      if ( copy == null )
      {
        diff = false;
      }
    }
    else
    {
      if ( copy != null )
      {
        if ( org.equals(copy) )
        {
          diff = false;
        }
      }
    }

    return diff;
  }


  /*****************************************************************************
   * 差分確認（Number）
   * @param org          オリジナル
   * @param copy         設定値
   *****************************************************************************
   */
  public static boolean isDiffer(
    Number  org
   ,Number  copy
  )
  {
    boolean diff = true;
    
    if ( org == null )
    {
      if ( copy == null )
      {
        diff = false;
      }
    }
    else
    {
      if ( copy != null )
      {
        if ( org.compareTo(copy) == 0 )
        {
          diff = false;
        }
      }
    }

    return diff;
  }
}