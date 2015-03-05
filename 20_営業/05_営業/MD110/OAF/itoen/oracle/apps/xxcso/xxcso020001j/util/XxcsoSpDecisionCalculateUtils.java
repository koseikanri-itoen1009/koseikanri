/*============================================================================
* ファイル名 : XxcsoSpDecisionCalculateUtils
* 概要説明   : SP専決計算ユーティリティクラス
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
* 2014-12-15 1.1  SCSK桐生和幸  [E_本稼動_12565]SP・契約書画面改修対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;

/*******************************************************************************
 * SP専決書の各種計算を行うためのユーティリティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionCalculateUtils 
{
  /*****************************************************************************
   * 売価別条件の定価換算率計算、売上粗利率計算
   * @param txn              OADBTransactionインスタンス
   * @param headerVo         SP専決ヘッダ登録／更新用ビューインスタンス
   * @param scVo             売価別条件登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void calculateSalesCondition(
    OADBTransaction                         txn
   ,XxcsoSpDecisionHeaderFullVOImpl         headerVo
   ,XxcsoSpDecisionScLineFullVOImpl         scVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    OracleCallableStatement stmt = null;
    List grossProfitList = new ArrayList();
    List salesPriceList = new ArrayList();
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.calculate_sc_line(");
      sql.append("     iv_fixed_price   => :1");
      sql.append("    ,iv_sales_price   => :2");
      sql.append("    ,iv_bm1_bm_rate   => :3");
      sql.append("    ,iv_bm1_bm_amt    => :4");
      sql.append("    ,iv_bm2_bm_rate   => :5");
      sql.append("    ,iv_bm2_bm_amt    => :6");
      sql.append("    ,iv_bm3_bm_rate   => :7");
      sql.append("    ,iv_bm3_bm_amt    => :8");
      sql.append("    ,on_gross_profit  => :9");
      sql.append("    ,on_sales_price   => :10");
      sql.append("    ,ov_bm_rate       => :11");
      sql.append("    ,ov_bm_amount     => :12");
      sql.append("    ,ov_bm_conv_rate  => :13");
      sql.append("    ,ov_errbuf        => :14");
      sql.append("    ,ov_retcode       => :15");
      sql.append("    ,ov_errmsg        => :16");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      /////////////////////////////////////
      // 各行の粗利額を取得
      /////////////////////////////////////
      while ( scRow != null )
      {
        stmt.setString(1,  scRow.getFixedPrice());
        stmt.setString(2,  scRow.getSalesPrice());
        stmt.setString(3,  scRow.getBm1BmRate());
        stmt.setString(4,  scRow.getBm1BmAmount());
        stmt.setString(5,  scRow.getBm2BmRate());
        stmt.setString(6,  scRow.getBm2BmAmount());
        stmt.setString(7,  scRow.getBm3BmRate());
        stmt.setString(8,  scRow.getBm3BmAmount());
        stmt.registerOutParameter(9,  OracleTypes.NUMBER);
        stmt.registerOutParameter(10, OracleTypes.NUMBER);
        stmt.registerOutParameter(11, OracleTypes.VARCHAR);
        stmt.registerOutParameter(12, OracleTypes.VARCHAR);
        stmt.registerOutParameter(13, OracleTypes.VARCHAR);
        stmt.registerOutParameter(14, OracleTypes.VARCHAR);
        stmt.registerOutParameter(15, OracleTypes.VARCHAR);
        stmt.registerOutParameter(16, OracleTypes.VARCHAR);

        XxcsoUtils.debug(txn, "execute stored start");
        stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

        NUMBER grossProfit = stmt.getNUMBER(9);
        NUMBER salesPrice  = stmt.getNUMBER(10);
        String bmRate      = stmt.getString(11);
        String bmAmount    = stmt.getString(12);
        String bmConvRate  = stmt.getString(13);
        String errBuf      = stmt.getString(14);
        String retCode     = stmt.getString(15);
        String errMsg      = stmt.getString(16);

        XxcsoUtils.debug(txn, "grossProfit = " + grossProfit.stringValue());
        XxcsoUtils.debug(txn, "salesPrice  = " + salesPrice.stringValue());
        XxcsoUtils.debug(txn, "errbuf      = " + errBuf);
        XxcsoUtils.debug(txn, "retCode     = " + retCode);
        XxcsoUtils.debug(txn, "errmsg      = " + errMsg);

        if ( ! "0".equals(retCode) )
        {
          throw
            XxcsoMessage.createCriticalErrorMessage(
              XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
             ,errBuf
            );
        }
        
        grossProfitList.add(grossProfit);
        salesPriceList.add(salesPrice);

        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               scRow.getBmRatePerSalesPrice()
              ,bmRate
             )
           )
        {
          scRow.setBmRatePerSalesPrice(bmRate);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               scRow.getBmAmountPerSalesPrice()
              ,bmAmount
             )
           )
        {
          scRow.setBmAmountPerSalesPrice(bmAmount);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               scRow.getBmConvRatePerSalesPrice()
              ,bmConvRate
             )
           )
        {
          scRow.setBmConvRatePerSalesPrice(bmConvRate);
        }
        
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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

    try
    {
      NUMBER totalGrossProfit = NUMBER.zero();
      NUMBER totalSalesPrice  = NUMBER.zero();
      
      for ( int i = 0; i < grossProfitList.size(); i++ )
      {
        NUMBER grossProfit = (NUMBER)grossProfitList.get(i);
        NUMBER salesPrice  = (NUMBER)salesPriceList.get(i);

        totalGrossProfit = totalGrossProfit.add(grossProfit);
        totalSalesPrice  = totalSalesPrice.add(salesPrice);
      }
      
      XxcsoUtils.debug(
        txn, "totalGrossProfit = " + totalGrossProfit.stringValue()
      );
      XxcsoUtils.debug(
        txn, "totalSalesPrice  = " + totalSalesPrice.stringValue()
      );

      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_gross_profit_rate(:2, :3);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setNUMBER(2, totalGrossProfit);
      stmt.setNUMBER(3, totalSalesPrice);
      
      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String grossProfitRate = stmt.getString(1);

      XxcsoUtils.debug(
        txn, "grossProfitRate = " + grossProfitRate
      );

      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getSalesGrossMarginRate()
            ,grossProfitRate
           )
         )
      {
        headerRow.setSalesGrossMarginRate(grossProfitRate);
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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
   * 全容器一律条件の定価換算率計算、売上粗利率計算
   * @param txn              OADBTransactionインスタンス
   * @param headerVo         SP専決ヘッダ登録／更新用ビューインスタンス
   * @param allCcVo          全容器一律条件登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void calculateAllCcCondition(
    OADBTransaction                         txn
   ,XxcsoSpDecisionHeaderFullVOImpl         headerVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl      allCcVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();

    OracleCallableStatement stmt = null;
    List grossProfitList = new ArrayList();
    List salesPriceList = new ArrayList();

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.calculate_cc_line(");
      sql.append("     iv_container_type  => :1");
      sql.append("    ,iv_discount_amt    => :2");
      sql.append("    ,iv_bm1_bm_rate     => :3");
      sql.append("    ,iv_bm1_bm_amt      => :4");
      sql.append("    ,iv_bm2_bm_rate     => :5");
      sql.append("    ,iv_bm2_bm_amt      => :6");
      sql.append("    ,iv_bm3_bm_rate     => :7");
      sql.append("    ,iv_bm3_bm_amt      => :8");
      sql.append("    ,on_gross_profit    => :9");
      sql.append("    ,on_sales_price     => :10");
      sql.append("    ,ov_bm_rate         => :11");
      sql.append("    ,ov_bm_amount       => :12");
      sql.append("    ,ov_bm_conv_rate    => :13");
      sql.append("    ,ov_errbuf          => :14");
      sql.append("    ,ov_retcode         => :15");
      sql.append("    ,ov_errmsg          => :16");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      /////////////////////////////////////
      // 各行の粗利額を取得
      /////////////////////////////////////
      while ( allCcRow != null )
      {
        String discountAmt = allCcRow.getDiscountAmt();
        if ( discountAmt == null || "".equals(discountAmt) )
        {
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 allCcRow.getBmRatePerSalesPrice()
                ,null
               )
             )
          {
            allCcRow.setBmRatePerSalesPrice(null);
          }
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 allCcRow.getBmAmountPerSalesPrice()
                ,null
               )
             )
          {
            allCcRow.setBmAmountPerSalesPrice(null);
          }
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 allCcRow.getBmConvRatePerSalesPrice()
                ,null
               )
             )
          {
            allCcRow.setBmConvRatePerSalesPrice(null);
          }
          
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
          continue;
        }
        
        stmt.setString(1,  allCcRow.getSpContainerType());
        stmt.setString(2,  allCcRow.getDiscountAmt());
        stmt.setString(3,  allCcRow.getBm1BmRate());
        stmt.setString(4,  allCcRow.getBm1BmAmount());
        stmt.setString(5,  allCcRow.getBm2BmRate());
        stmt.setString(6,  allCcRow.getBm2BmAmount());
        stmt.setString(7,  allCcRow.getBm3BmRate());
        stmt.setString(8,  allCcRow.getBm3BmAmount());
        stmt.registerOutParameter(9,  OracleTypes.NUMBER);
        stmt.registerOutParameter(10, OracleTypes.NUMBER);
        stmt.registerOutParameter(11, OracleTypes.VARCHAR);
        stmt.registerOutParameter(12, OracleTypes.VARCHAR);
        stmt.registerOutParameter(13, OracleTypes.VARCHAR);
        stmt.registerOutParameter(14, OracleTypes.VARCHAR);
        stmt.registerOutParameter(15, OracleTypes.VARCHAR);
        stmt.registerOutParameter(16, OracleTypes.VARCHAR);

        XxcsoUtils.debug(txn, "execute stored start");
        stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

        NUMBER grossProfit = stmt.getNUMBER(9);
        NUMBER salesPrice  = stmt.getNUMBER(10);
        String bmRate      = stmt.getString(11);
        String bmAmount    = stmt.getString(12);
        String bmConvRate  = stmt.getString(13);
        String errBuf      = stmt.getString(14);
        String retCode     = stmt.getString(15);
        String errMsg      = stmt.getString(16);

        XxcsoUtils.debug(txn, "grossProfit = " + grossProfit.stringValue());
        XxcsoUtils.debug(txn, "salesPrice  = " + salesPrice.stringValue());
        XxcsoUtils.debug(txn, "errbuf      = " + errBuf);
        XxcsoUtils.debug(txn, "retCode     = " + retCode);
        XxcsoUtils.debug(txn, "errmsg      = " + errMsg);

        if ( ! "0".equals(retCode) )
        {
          throw
            XxcsoMessage.createCriticalErrorMessage(
              XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
             ,errBuf
            );
        }

        grossProfitList.add(grossProfit);
        salesPriceList.add(salesPrice);

        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               allCcRow.getBmRatePerSalesPrice()
              ,bmRate
             )
           )
        {
          allCcRow.setBmRatePerSalesPrice(bmRate);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               allCcRow.getBmAmountPerSalesPrice()
              ,bmAmount
             )
           )
        {
          allCcRow.setBmAmountPerSalesPrice(bmAmount);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               allCcRow.getBmConvRatePerSalesPrice()
              ,bmConvRate
             )
           )
        {
          allCcRow.setBmConvRatePerSalesPrice(bmConvRate);
        }
        
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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

    try
    {
      NUMBER totalGrossProfit = NUMBER.zero();
      NUMBER totalSalesPrice  = NUMBER.zero();
      
      for ( int i = 0; i < grossProfitList.size(); i++ )
      {
        NUMBER grossProfit = (NUMBER)grossProfitList.get(i);
        NUMBER salesPrice  = (NUMBER)salesPriceList.get(i);

        totalGrossProfit = totalGrossProfit.add(grossProfit);
        totalSalesPrice  = totalSalesPrice.add(salesPrice);
      }
      
      XxcsoUtils.debug(
        txn, "totalGrossProfit = " + totalGrossProfit.stringValue()
      );
      XxcsoUtils.debug(
        txn, "totalSalesPrice  = " + totalSalesPrice.stringValue()
      );

      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_gross_profit_rate(:2, :3);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setNUMBER(2, totalGrossProfit);
      stmt.setNUMBER(3, totalSalesPrice);
      
      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String grossProfitRate = stmt.getString(1);

      XxcsoUtils.debug(
        txn, "grossProfitRate = " + grossProfitRate
      );

      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getSalesGrossMarginRate()
            ,grossProfitRate
           )
         )
      {
        headerRow.setSalesGrossMarginRate(grossProfitRate);
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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
   * 容器別条件の定価換算率計算、売上粗利率計算
   * @param txn              OADBTransactionインスタンス
   * @param headerVo         SP専決ヘッダ登録／更新用ビューインスタンス
   * @param selCcVo          容器別条件登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void calculateSelCcCondition(
    OADBTransaction                         txn
   ,XxcsoSpDecisionHeaderFullVOImpl         headerVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl      selCcVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();

    OracleCallableStatement stmt = null;
    List grossProfitList = new ArrayList();
    List salesPriceList = new ArrayList();

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.calculate_cc_line(");
      sql.append("     iv_container_type  => :1");
      sql.append("    ,iv_discount_amt    => :2");
      sql.append("    ,iv_bm1_bm_rate     => :3");
      sql.append("    ,iv_bm1_bm_amt      => :4");
      sql.append("    ,iv_bm2_bm_rate     => :5");
      sql.append("    ,iv_bm2_bm_amt      => :6");
      sql.append("    ,iv_bm3_bm_rate     => :7");
      sql.append("    ,iv_bm3_bm_amt      => :8");
      sql.append("    ,on_gross_profit    => :9");
      sql.append("    ,on_sales_price     => :10");
      sql.append("    ,ov_bm_rate         => :11");
      sql.append("    ,ov_bm_amount       => :12");
      sql.append("    ,ov_bm_conv_rate    => :13");
      sql.append("    ,ov_errbuf          => :14");
      sql.append("    ,ov_retcode         => :15");
      sql.append("    ,ov_errmsg          => :16");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      /////////////////////////////////////
      // 各行の粗利額を取得
      /////////////////////////////////////
      while ( selCcRow != null )
      {
        String discountAmt = selCcRow.getDiscountAmt();
        if ( discountAmt == null || "".equals(discountAmt) )
        {
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 selCcRow.getBmRatePerSalesPrice()
                ,null
               )
             )
          {
            selCcRow.setBmRatePerSalesPrice(null);
          }
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 selCcRow.getBmAmountPerSalesPrice()
                ,null
               )
             )
          {
            selCcRow.setBmAmountPerSalesPrice(null);
          }
          if ( XxcsoSpDecisionReflectUtils.isDiffer(
                 selCcRow.getBmConvRatePerSalesPrice()
                ,null
               )
             )
          {
            selCcRow.setBmConvRatePerSalesPrice(null);
          }

          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
          continue;
        }
        
        stmt.setString(1,  selCcRow.getSpContainerType());
        stmt.setString(2,  selCcRow.getDiscountAmt());
        stmt.setString(3,  selCcRow.getBm1BmRate());
        stmt.setString(4,  selCcRow.getBm1BmAmount());
        stmt.setString(5,  selCcRow.getBm2BmRate());
        stmt.setString(6,  selCcRow.getBm2BmAmount());
        stmt.setString(7,  selCcRow.getBm3BmRate());
        stmt.setString(8,  selCcRow.getBm3BmAmount());
        stmt.registerOutParameter(9,  OracleTypes.NUMBER);
        stmt.registerOutParameter(10, OracleTypes.NUMBER);
        stmt.registerOutParameter(11, OracleTypes.VARCHAR);
        stmt.registerOutParameter(12, OracleTypes.VARCHAR);
        stmt.registerOutParameter(13, OracleTypes.VARCHAR);
        stmt.registerOutParameter(14, OracleTypes.VARCHAR);
        stmt.registerOutParameter(15, OracleTypes.VARCHAR);
        stmt.registerOutParameter(16, OracleTypes.VARCHAR);

        XxcsoUtils.debug(txn, "execute stored start");
        stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

        NUMBER grossProfit = stmt.getNUMBER(9);
        NUMBER salesPrice  = stmt.getNUMBER(10);
        String bmRate      = stmt.getString(11);
        String bmAmount    = stmt.getString(12);
        String bmConvRate  = stmt.getString(13);
        String errBuf      = stmt.getString(14);
        String retCode     = stmt.getString(15);
        String errMsg      = stmt.getString(16);

        XxcsoUtils.debug(txn, "grossProfit = " + grossProfit.stringValue());
        XxcsoUtils.debug(txn, "salesPrice  = " + salesPrice.stringValue());
        XxcsoUtils.debug(txn, "errbuf      = " + errBuf);
        XxcsoUtils.debug(txn, "retCode     = " + retCode);
        XxcsoUtils.debug(txn, "errmsg      = " + errMsg);

        if ( ! "0".equals(retCode) )
        {
          throw
            XxcsoMessage.createCriticalErrorMessage(
              XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
             ,errBuf
            );
        }

        grossProfitList.add(grossProfit);
        salesPriceList.add(salesPrice);

        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               selCcRow.getBmRatePerSalesPrice()
              ,bmRate
             )
           )
        {
          selCcRow.setBmRatePerSalesPrice(bmRate);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               selCcRow.getBmAmountPerSalesPrice()
              ,bmAmount
             )
           )
        {
          selCcRow.setBmAmountPerSalesPrice(bmAmount);
        }
        if ( XxcsoSpDecisionReflectUtils.isDiffer(
               selCcRow.getBmConvRatePerSalesPrice()
              ,bmConvRate
             )
           )
        {
          selCcRow.setBmConvRatePerSalesPrice(bmConvRate);
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
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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

    try
    {
      NUMBER totalGrossProfit = NUMBER.zero();
      NUMBER totalSalesPrice  = NUMBER.zero();
      
      for ( int i = 0; i < grossProfitList.size(); i++ )
      {
        NUMBER grossProfit = (NUMBER)grossProfitList.get(i);
        NUMBER salesPrice  = (NUMBER)salesPriceList.get(i);

        totalGrossProfit = totalGrossProfit.add(grossProfit);
        totalSalesPrice  = totalSalesPrice.add(salesPrice);
      }
      
      XxcsoUtils.debug(
        txn, "totalGrossProfit = " + totalGrossProfit.stringValue()
      );
      XxcsoUtils.debug(
        txn, "totalSalesPrice  = " + totalSalesPrice.stringValue()
      );

      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := xxcso_020001j_pkg.get_gross_profit_rate(:2, :3);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.VARCHAR);
      stmt.setNUMBER(2, totalGrossProfit);
      stmt.setNUMBER(3, totalSalesPrice);
      
      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String grossProfitRate = stmt.getString(1);

      XxcsoUtils.debug(
        txn, "grossProfitRate = " + grossProfitRate
      );

      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getSalesGrossMarginRate()
            ,grossProfitRate
           )
         )
      {
        headerRow.setSalesGrossMarginRate(grossProfitRate);
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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
   * 概算年間損益計算
   * @param txn              OADBTransactionインスタンス
   * @param headerVo         SP専決ヘッダ登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void calculateEstimateYearProfit(
    OADBTransaction                         txn
   ,XxcsoSpDecisionHeaderFullVOImpl         headerVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");
    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

// 2014-12-15 [E_本稼動_12565] Add Start
    // 契約年数の設定
    int    cnvContractYearDate = Integer.valueOf( headerRow.getContractYearDate() ).intValue();
    String contractYearDate    = headerRow.getContractYearDate();

    if ( cnvContractYearDate == 0 )
    {
      contractYearDate = "1";
    }
// 2014-12-15 [E_本稼動_12565] Add End

    OracleCallableStatement stmt = null;
    
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_020001j_pkg.calculate_est_year_profit(");
      sql.append("     iv_sales_month               => :1");
      sql.append("    ,iv_sales_gross_margin_rate   => :2");
      sql.append("    ,iv_bm_rate                   => :3");
      sql.append("    ,iv_lease_charge_month        => :4");
      sql.append("    ,iv_construction_charge       => :5");
      sql.append("    ,iv_contract_year_date        => :6");
      sql.append("    ,iv_install_support_amt       => :7");
      sql.append("    ,iv_electricity_amount        => :8");
      sql.append("    ,iv_electricity_amt_month     => :9");
      sql.append("    ,ov_sales_year                => :10");
      sql.append("    ,ov_year_gross_margin_amt     => :11");
      sql.append("    ,ov_vd_sales_charge           => :12");
      sql.append("    ,ov_install_support_amt_year  => :13");
      sql.append("    ,ov_vd_lease_charge           => :14");
      sql.append("    ,ov_electricity_amt_month     => :15");
      sql.append("    ,ov_electricity_amt_year      => :16");
      sql.append("    ,ov_transportation_charge     => :17");
      sql.append("    ,ov_labor_cost_other          => :18");
      sql.append("    ,ov_total_cost                => :19");
      sql.append("    ,ov_operating_profit          => :20");
      sql.append("    ,ov_operating_profit_rate     => :21");
      sql.append("    ,ov_break_even_point          => :22");
      sql.append("    ,ov_errbuf                    => :23");
      sql.append("    ,ov_retcode                   => :24");
      sql.append("    ,ov_errmsg                    => :25");
      sql.append("  );");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());
      
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1,  headerRow.getSalesMonth());
      stmt.setString(2,  headerRow.getSalesGrossMarginRate());
      stmt.setString(3,  headerRow.getBmRate());
      stmt.setString(4,  headerRow.getLeaseChargeMonth());
      stmt.setString(5,  headerRow.getConstructionCharge());
// 2014-12-15 [E_本稼動_12565] Mod Start
//      stmt.setString(6,  headerRow.getContractYearDate());
//      stmt.setString(7,  headerRow.getInstallSupportAmt());
      stmt.setString(6,  contractYearDate);
      stmt.setString(7,  headerRow.getInstallSuppAmt());
// 2014-12-15 [E_本稼動_12565] Mod End
      stmt.setString(8,  headerRow.getElectricityAmount());
      stmt.setString(9,  headerRow.getElectricityAmtMonth());
      stmt.registerOutParameter(10,  OracleTypes.VARCHAR);
      stmt.registerOutParameter(11, OracleTypes.VARCHAR);
      stmt.registerOutParameter(12, OracleTypes.VARCHAR);
      stmt.registerOutParameter(13, OracleTypes.VARCHAR);
      stmt.registerOutParameter(14, OracleTypes.VARCHAR);
      stmt.registerOutParameter(15, OracleTypes.VARCHAR);
      stmt.registerOutParameter(16, OracleTypes.VARCHAR);
      stmt.registerOutParameter(17, OracleTypes.VARCHAR);
      stmt.registerOutParameter(18, OracleTypes.VARCHAR);
      stmt.registerOutParameter(19, OracleTypes.VARCHAR);
      stmt.registerOutParameter(20, OracleTypes.VARCHAR);
      stmt.registerOutParameter(21, OracleTypes.VARCHAR);
      stmt.registerOutParameter(22, OracleTypes.VARCHAR);
      stmt.registerOutParameter(23, OracleTypes.VARCHAR);
      stmt.registerOutParameter(24, OracleTypes.VARCHAR);
      stmt.registerOutParameter(25, OracleTypes.VARCHAR);

      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String salesYear                = stmt.getString(10);
      String yearGrossMarginAmt       = stmt.getString(11);
      String vdSalesCharge            = stmt.getString(12);
      String installSupportAmtYear    = stmt.getString(13);
      String vdLeaseCharge            = stmt.getString(14);
      String electricityAmtMonth      = stmt.getString(15);
      String electricityAmtYear       = stmt.getString(16);
      String transportationCharge     = stmt.getString(17);
      String laborCostOther           = stmt.getString(18);
      String totalCost                = stmt.getString(19);
      String operatingProfit          = stmt.getString(20);
      String operatingProfitRate      = stmt.getString(21);
      String breakEvenPoint           = stmt.getString(22);
      String errBuf                   = stmt.getString(23);
      String retCode                  = stmt.getString(24);
      String errMsg                   = stmt.getString(25);

      XxcsoUtils.debug(
        txn, "salesYear              = " + salesYear
      );
      XxcsoUtils.debug(
        txn, "yearGrossMarginAmt     = " + yearGrossMarginAmt
      );
      XxcsoUtils.debug(
        txn, "vdSalesCharge          = " + vdSalesCharge
      );
      XxcsoUtils.debug(
        txn, "installSupportAmtYear  = " + installSupportAmtYear
      );
      XxcsoUtils.debug(
        txn, "vdLeaseCharge          = " + vdLeaseCharge
      );
      XxcsoUtils.debug(
        txn, "electricityAmtMonth    = " + electricityAmtMonth
      );
      XxcsoUtils.debug(
        txn, "electricityAmtYear     = " + electricityAmtYear
      );
      XxcsoUtils.debug(
        txn, "transportationCharge   = " + transportationCharge
      );
      XxcsoUtils.debug(
        txn, "laborCostOther         = " + laborCostOther
      );
      XxcsoUtils.debug(
        txn, "totalCost             = " + totalCost
      );
      XxcsoUtils.debug(
        txn, "operatingProfit       = " + operatingProfit
      );
      XxcsoUtils.debug(
        txn, "operatingProfitRate   = " + operatingProfitRate
      );
      XxcsoUtils.debug(
        txn, "breakEvenPoint        = " + breakEvenPoint
      );
      XxcsoUtils.debug(
        txn, "errbuf                = " + errBuf
      );
      XxcsoUtils.debug(
        txn, "retCode               = " + retCode
      );
      XxcsoUtils.debug(
        txn, "errmsg                = " + errMsg
      );

      if ( ! "0".equals(retCode) )
      {
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
           ,errBuf
          );
      }

      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getSalesYear()
            ,salesYear
           )
         )
      {
        headerRow.setSalesYear(salesYear);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getYearGrossMarginAmt()
            ,yearGrossMarginAmt
           )
         )
      {
        headerRow.setYearGrossMarginAmt(yearGrossMarginAmt);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getVdSalesCharge()
            ,vdSalesCharge
           )
         )
      {
        headerRow.setVdSalesCharge(vdSalesCharge);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getInstallSupportAmtYear()
            ,installSupportAmtYear
           )
         )
      {
        headerRow.setInstallSupportAmtYear(installSupportAmtYear);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getVdLeaseCharge()
            ,vdLeaseCharge
           )
         )
      {
        headerRow.setVdLeaseCharge(vdLeaseCharge);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getElectricityAmtMonth()
            ,electricityAmtYear
           )
         )
      {
        headerRow.setElectricityAmtMonth(electricityAmtMonth);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getElectricityAmtYear()
            ,electricityAmtYear
           )
         )
      {
        headerRow.setElectricityAmtYear(electricityAmtYear);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getTransportationCharge()
            ,transportationCharge
           )
         )
      {
        headerRow.setTransportationCharge(transportationCharge);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getLaborCostOther()
            ,laborCostOther
           )
         )
      {
        headerRow.setLaborCostOther(laborCostOther);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getTotalCost()
            ,totalCost
           )
         )
      {
        headerRow.setTotalCost(totalCost);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getOperatingProfit()
            ,operatingProfit
           )
         )
      {
        headerRow.setOperatingProfit(operatingProfit);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getOperatingProfitRate()
            ,operatingProfitRate
           )
         )
      {
        headerRow.setOperatingProfitRate(operatingProfitRate);
      }
      if ( XxcsoSpDecisionReflectUtils.isDiffer(
             headerRow.getBreakEvenPoint()
            ,breakEvenPoint
           )
         )
      {
        headerRow.setBreakEvenPoint(breakEvenPoint);
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CALC_LINE
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
}